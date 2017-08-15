# Description:
#   Listens for event notifications from the ci-webhook listeners and handles Travis CI notifications

url           = require('url')
querystring   = require('querystring')
starwars      = require('starwars')
common        = require("./common.coffee")

module.exports = (robot) ->

  robot.router.post "/hubot/appveyor", (req, res) ->
    try
      if (common.logWebHooks())
        robot.logger.info("Appveyor webhook received: ", req.body)

      robot.emit "appveyor-event", req.body
    catch error
      robot.logger.error "Webhook listener error: #{error.stack}. Request: #{req.body}"

    res.end ""

  robot.on "appveyor-event", (notification) ->
    # make sure the event comes from the project configured by minibot
    if not notification.eventData.buildUrl.startsWith("https://ci.appveyor.com/project/minishift-bot/minishift")
      return

    if (notification.eventData.failed is true)
      if (notification.eventData.isPullRequest is true)
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Appveyor reports, pull request build https://github.com/#{notification.eventData.repositoryName}/pull/#{notification.eventData.pullRequestId} failed"
      else
        robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Red alert, Appveyor reports a failed master build: #{notification.eventData.buildUrl}.
          Commit by #{notification.eventData.commitAuthor}: #{notification.eventData.commitMessage}"
    else
      if (common.notifyOnSuccess())
        if (notification.eventData.isPullRequest is true)
          robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Appveyor reports, pull request build https://github.com/#{notification.eventData.repositoryName}/pull/#{notification.eventData.pullRequestId} succeeded"
        else
          robot.messageRoom process.env.HUBOT_IRC_ROOMS, "Appveyor reports another successful master build: #{notification.eventData.buildUrl}.
            Commit by #{notification.eventData.commitAuthor}: #{notification.eventData.commitMessage}"
