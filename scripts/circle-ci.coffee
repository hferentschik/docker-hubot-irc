# Description:
#   Listens for event notifications from the ci-webhook listeners and handles Travis CI notifications
url           = require('url')

debug = false

module.exports = (robot) ->

  robot.router.post "/hubot/circleci", (req, res) ->
    try
      if (debug)
        robot.logger.info("Webhook received: ", req)

      robot.emit "circle-ci-event", req.body.payload
    catch error
      robot.logger.error "Webhook listener error: #{error.stack}. Request: #{req.body}"

    res.end ""

  robot.on "circle-ci-event", (payload) ->

    # Only care about master notifications
    if not payload.build_url.startsWith("https://circleci.com/gh/minishift/minishift")
      return

    if payload.branch.startsWith('pull')
      if payload.status is 'success'
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Circle CI reports, pull request build https://github.com/minishift/minishift/#{payload.branch} succeeded"
      else
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Circle CI reports, pull request build https://github.com/minishift/minishift/#{payload.branch} failed"
    else
      if payload.status is 'success'
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Circle CI reports, another successful master build: #{payload.build_url}. Commit by #{payload.committer_name}: #{payload.message}"
      else
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Code one emergency, Circle CI reports broken master build: #{payload.build_url} Commit by #{payload.committer_name}: #{payload.subject}"



