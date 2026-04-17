// 1. Loading the config file first to prevent initialization errors
const config = require('./config/config.json')
const defaultConfig = config.development

// 2. Override config with environment variables (essential for Docker/Cloud deployment)
defaultConfig.webservice_host = process.env.WEBSERVICE_HOST || defaultConfig.webservice_host
defaultConfig.webservice_port = process.env.WEBSERVICE_PORT || defaultConfig.webservice_port

// 3. Set global configuration
global.gConfig = defaultConfig

// 4. Load required modules
var http = require('http')
var url = require('url')
const { parse } = require('querystring')
var fs = require('fs')

// Generating some constants to be used to create the common HTML elements.
var header = '<!doctype html><html>' + '<head>'

var body =
  '</head><body><div id="container">' +
  '<div id="logo">' +
  global.gConfig.app_name +
  '</div>' +
  '<div id="space"></div>' +
  '<div id="form">' +
  '<form id="form" action="/" method="post"><center>' +
  '<label class="control-label">Name:</label>' +
  '<input class="input" type="text" name="name"/><br />' +
  '<label class="control-label">Ingredients:</label>' +
  '<input class="input" type="text" name="ingredients" /><br />' +
  '<label class="control-label">Prep Time:</label>' +
  '<input class="input" type="number" name="prepTimeInMinutes" /><br />'

var submitButton = '<button class="button button1">Submit</button>' + '</div></form>'

var endBody = '</div></body></html>'

http
  .createServer(function (req, res) {
    console.log(req.url)

    // Avoid duplicated calls (due to the favicon.ico)
    if (req.url === '/favicon.ico') {
      res.writeHead(200, { 'Content-Type': 'image/x-icon' })
      res.end()
      console.log('favicon requested')
    } else {
      res.writeHead(200, { 'Content-Type': 'text/html' })

      var fileContents = fs.readFileSync('./public/default.css', { encoding: 'utf8' })
      res.write(header)
      res.write('<style>' + fileContents + '</style>')
      res.write(body)
      res.write(submitButton)

      var timeout = 0

      // Handle Form Submission (POST)
      if (req.method === 'POST') {
        timeout = 2000

        var myJSONObject = {}
        var qs = require('querystring')

        let postBody = ''
        req.on('data', (chunk) => {
          postBody += chunk.toString()
        })

        req.on('end', () => {
          var post = qs.parse(postBody)
          myJSONObject['name'] = post['name']
          myJSONObject['ingredients'] = post['ingredients'].split(',')
          myJSONObject['prepTimeInMinutes'] = post['prepTimeInMinutes']

          // Send the data to the Web Service
          const options = {
            hostname: global.gConfig.webservice_host,
            port: global.gConfig.webservice_port,
            path: '/recipe',
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
          }

          const req2 = http.request(options, (resp) => {
            let data = ''
            resp.on('data', (chunk) => {
              data += chunk
            })
            resp.on('end', () => {
              console.log('Data Saved!')
            })
          })

          req2.on('error', (e) => {
            console.error(`Problem with request: ${e.message}`)
          })

          req2.write(JSON.stringify(myJSONObject))
          req2.end()
        })
      }

      // Display existing recipes
      {
        if (req.method === 'POST') {
          res.write('<div id="space"></div>')
          res.write('<div id="logo">New recipe saved successfully! </div>')
          res.write('<div id="space"></div>')
        }

        setTimeout(function () {
          const options = {
            hostname: global.gConfig.webservice_host,
            port: global.gConfig.webservice_port,
            path: '/recipes',
            method: 'GET',
          }

          const reqGet = http.request(options, (resp) => {
            let data = ''
            resp.on('data', (chunk) => {
              data += chunk
            })
            resp.on('end', () => {
              res.write('<div id="space"></div>')
              res.write('<div id="logo">Your Previous Recipes</div>')
              res.write('<div id="space"></div>')
              res.write('<div id="results">Name | Ingredients | PrepTime')
              res.write('<div id="space"></div>')

              try {
                const myArr = JSON.parse(data)
                let i = 0
                while (i < myArr.length) {
                  res.write(myArr[i].name + ' | ' + myArr[i].ingredients + ' | ')
                  res.write(myArr[i].prepTimeInMinutes + '<br/>')
                  i++
                }
              } catch (e) {
                res.write('Error loading recipes. Ensure Backend is running.')
              }

              res.write('</div><div id="space"></div>')
              res.end(endBody)
            })
          })

          reqGet.on('error', (e) => {
            console.error(`Problem with request: ${e.message}`)
            res.write('<div>Could not connect to Backend. Check if the Spring Boot app is running on ' + global.gConfig.webservice_port + '</div>')
            res.end(endBody)
          })

          reqGet.end()
        }, timeout)
      }
    }
  })
  .listen(global.gConfig.exposedPort, () => {
    console.log(`FE Server running at http://localhost:${global.gConfig.exposedPort}`)
  })
