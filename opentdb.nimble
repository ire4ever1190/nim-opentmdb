# Package

version       = "1.0.0"
author        = "Jake Leahy"
description   = "Wrapper around the open trivia db api"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.0"

task genDoc, "Generates the doc":
    # exec("nim doc2 --git.url:https://github.com/ire4ever1190/nim-opentmdb --index:on --project src/opentdb.nim")
    mvDir("src/htmldocs", "docs")
    writeFile("docs/index.html", """
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="Refresh" content="0; url=opentdb.html" />
      </head>
      <body>
        <p>Click <a href="opentdb.html">this link</a> if this does not redirect you.</p>
      </body>
    </html>
    """)
