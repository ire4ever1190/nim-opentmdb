# Package

version       = "1.0.1"
author        = "Jake Leahy"
description   = "Wrapper around the open trivia db api"
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.2.0"

task genDoc, "Generates the doc":
    rmDir("docs")
    exec("nim doc2 --outdir:docs --git.url:https://github.com/ire4ever1190/nim-opentmdb --git.commit:master --index:on --project src/opentdb.nim")
    exec("nim buildIndex -o:docs/theindex.html docs")
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
