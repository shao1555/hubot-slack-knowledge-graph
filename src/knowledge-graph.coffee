phantom = require 'phantom'
temp = require 'temp'
fs = require 'fs'
slackClient = require 'slack-client'

USER_AGENT_STRING = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2650.0 Safari/537.36'

module.exports = (robot) ->
  robot.hear /^\? (.+)/i, (res) ->
    temp.track()
    phantom.create().then (ph) ->
      ph.createPage().then (page) ->
        page.setting('userAgent', USER_AGENT_STRING).then ->
          page.open("https://www.google.com/search?q=#{encodeURIComponent res.match[1]}").then (status) ->
            if status == 'success'
              page.evaluate(() ->
                element = document.querySelector('div#cwmcwd') || document.querySelector('g-card div') || document.querySelector('.kp-blk') || document.querySelector('div.g div.rreh')|| document.querySelector('div#ires .card-section')
                if element != null
                  element.getBoundingClientRect()
                else
                  undefined
              ).then (rect) ->
                console.log(rect)
                if rect != null
                  page.property('clipRect',
                    top: rect.top,
                    left: rect.left,
                    width: rect.width,
                    height: rect.height
                  ).then ->
                    screenShotFile = temp.path(suffix: '.png')
                    page.render(screenShotFile).then ->
                      slackWebClient = new slackClient.WebClient(process.env.HUBOT_SLACK_TOKEN)
                      slackWebClient.files.upload {file: fs.createReadStream(screenShotFile), channels: "##{res.envelope.room}"}, (error, info) ->
                        if error != undefined
                          console.log(error)
                          res.send('upload failed')
                        temp.cleanupSync()
                        ph.exit()
                else
                  res.send('Not found')
