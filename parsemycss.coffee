cssom = require 'cssom'
fs = require 'fs'
jsdom = require 'jsdom'

# read some css
fs.readFile 'sample.css', (error, data) ->
    if error
        # ah sheeett
        return console.log 'Failed to read the CSS file', error

    # set our css
    css = data.toString 'ascii'

    # stick it through the awesome cssom
    rules = cssom.parse css

    # check for rules
    try
        if rules.cssRules.length > 0
            # read our template into a var
            fs.readFile 'template.html', (error, data) ->
                if error
                    # lame balls
                    return console.log 'Failed to read the HTML template file', error

                # set our html
                html = data.toString 'ascii'

                # set up our dom
                jsdom.env html, [ 'http://code.jquery.com/jquery-1.5.min.js' ], (error, window) ->
                    if error
                        # something gone damn wrong
                        return console.log 'Failed to init jsdom', error

                    # set jquery
                    $ = window.$

                    # let's add our js to the head
                    head = $ 'head'
                    head.append '<style type="text/css">' + css + '</style>'

                    # begin building the html elements
                    for rule in rules.cssRules
                        do (rule) ->
                            # check that we haz some selectors
                            if !rule.selectorText
                                return console.log 'No selector text found on rule' #, rule

                            # begin by splitting our rule into selector lists
                            selectors = rule.selectorText.split ','

                            # run through our selectors and begin to create our elements
                            for selector in selectors
                                do (selector) ->
                                    # prepare our selector
                                    selector = selector.trim()
                                    selector = selector.replace /\s\W\s/g, '' # this gets rid of >, +, etc...

                                    # split our selector into elements, ids and classes ready to turn into HTML
                                    tags = selector.split ' '

                                    # prepare our html row
                                    row = $ '<div><h1>' + selector + '</h1></div>'

                                    # add it to the dom
                                    body = $ 'body'
                                    body.append row

                                    # create our last element to append elements to
                                    last = $ '<div />'

                                    # append its ass to the row
                                    row.append last

                                    for tag in tags
                                        do (tag) ->
                                            # let's parse the components of the tag in the element, id and classes
                                            matches = tag.replace /^([\*|\w|\-]+)?(#[\w|\-]+)?(\.[\w|\-|\.]+)*(\[.+\])*(::?[\w|\-]+)*$/gm, '$1,$2,$3,$4,$5'

                                            # assign our matches into our element, id, etc...
                                            [ element, id, classes, attr, pseudo ] = matches.split ','

                                            # create our element and append it to the last element
                                            element = $ '<' + ( element || 'div' ) + ' />'

                                            # add our id
                                            if id
                                                element.attr 'id', id

                                            # add our classes
                                            if classes
                                                classes = classes.replace '.', ' '
                                                classes = classes.trim()

                                                element.attr 'class', classes

                                            # add our attr
                                            if attr
                                                # clean it up
                                                attr = attr.replace /^\[([\w|\-]+)?\W?=[\'|\"]?([\w|\-]+)[\'|\"]?\](\[[^\]]+\])?$/gm, '$1=$2'
                                                [ attrName, attrProp ] = attr.split '='

                                                # only add attr if there's a prop
                                                if attrProp
                                                    element.attr attrName, attrProp

                                            # finally add our element to our last element
                                            last = last.append element


                    # now let's write the html out
                    console.log window.document.innerHTML
                    fs.writeFile 'css.html', window.document.innerHTML, (error) ->
                        if error
                            # lame!
                            console.log 'Failed to write end file', error

        else
            # why would you parse a 0 rule css file?!
            console.log '0 rules round'

    catch e
        # so silly
        console.log 'No rules found', e
    
