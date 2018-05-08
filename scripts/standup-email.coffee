# Email log
#
# requires nodemailer
# requires following environment variable
#    HUBOT_STANDUP_EMAIL_ORIGIN_ADDRESS: email address to send logs from
#
# attempts to invoke local MTA at /usr/sbin/sendmail. modify if your system
# doesn't support this.
#
module.exports = (robot) ->
  robot.brain.on 'standupLog', (group, room, response, logs) ->
    postEmail robot, group, room, response, logs

  robot.respond /email (.*) standup logs? to (.*) *$/i, (msg) ->
    group = msg.match[1]
    email_address = msg.match[2]
    robot.brain.data.emailGroups or= {}
    robot.brain.data.emailGroups[group] = email_address
    if buff = robot.brain.data.tempEmailBuffer?[group]
      postEmail(robot, group, msg.message.user.room, msg, buff)
      delete robot.brain.data.tempEmailBuffer[group]
    msg.send "OK, I willl send standup logs to #{email_address}."


  robot.respond /no standup emails for (.*) *$/i, (msg) ->
    group = msg.match[1]
    robot.brain.data.emailGroups[group]=''
    msg.send "OK, I willl send standup logs to /dev/null."

postEmail = (robot, group, room, response, logs) ->
  nodemailer = require 'nodemailer'

  emailaddress = getEmailGroup robot, group
  if emailaddress is undefined
    response.send "Tell me what email address to send archives. Say '#{robot.name} email #{group} standup logs to <EMAIL_ADDRESS>'. Say '#{robot.name} no standup emails for #{group}' if you don't need logs."
    robot.brain.data.tempEmailBuffer or= {}
    robot.brain.data.tempEmailBuffer[group] = logs
  else if emailaddress is ''
    # do nothing
  else

# try and send mail using local MTA

    sendmail = nodemailer.createTransport "sendmail",
      path: "/usr/sbin/sendmail"

    body = makeBody robot, group, logs

    date = new Date(logs[0].time)

    mailoptions =  {
      from: process.env.HUBOT_STANDUP_EMAIL_ORIGIN_ADDRESS
      to: emailaddress
      subject: "Standup logs for #{group} for #{date.toLocaleDateString()}"
      text: body
    }
  
    sendmail.sendMail mailoptions, (error, msg) ->
      if error
        response.send "Posting to the group #{group_id} FAILED: #{msg}"
      else
        response.send "Posting to email #{emailaddress}"

getEmailGroup = (robot, group) ->
  robot.brain.data.emailGroups or= {}
  robot.brain.data.emailGroups[group]

makeBody = (robot, group, logs) ->
  # TODO templatize?
  date = new Date(logs[0].time)
  body = "Standup log for #{group}: #{date.toLocaleDateString()}\n==================================\n"

  prev = undefined
  for log in logs
    body += "(#{new Date(log.time).toLocaleTimeString()}) <#{log.message.user.name}> #{log.message.text}\n"

  body
