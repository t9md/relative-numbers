{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorElement = @editor.element


    @gutter = @editor.addGutter(name: 'relative-numbers')
    @gutter.view = this

    try
      # Preferred: Subscribe to any editor model changes
      @subscriptions.add @editor.onDidChange(@_update)
    catch
      # Fallback: Subscribe to initialization and editor changes
      @subscriptions.add @editorElement.onDidAttach(@_update)
      @subscriptions.add @editor.onDidStopChanging(@_update)

    # Subscribe for when the cursor position changes
    @subscriptions.add @editor.onDidChangeCursorPosition(@_update)

    # Update when scrolling
    @subscriptions.add @editorElement.onDidChangeScrollTop(@_update)

    @subscriptions.add atom.config.observe 'relative-numbers.trueNumberCurrentLine', (value) =>
      @trueNumberCurrentLine = value
      @_update()

    @lineNumberGutterElement = atom.views.getView(@editor.gutterWithName('line-number'))
    @subscriptions.add atom.config.observe 'relative-numbers.showAbsoluteNumbers', (value) =>
      @showAbsoluteNumbers = value
      @lineNumberGutterElement.classList.toggle('show-absolute', @showAbsoluteNumbers)

    @subscriptions.add atom.config.observe 'relative-numbers.startAtOne', (value) =>
      @startAtOne = value
      @_update()

    @subscriptions.add atom.config.onDidChange 'relative-numbers.softWrapsCount', (value) =>
      @softWrapsCount = value
      @_update()


    # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_update()

  destroy: ->
    @subscriptions.dispose()
    @_undo()
    @gutter.destroy()

  _spacer: (totalLines, currentIndex) ->
    width = Math.max(0, String(totalLines).length - String(currentIndex).length)
    '&nbsp;'.repeat(width)

  # Update the line numbers on the editor
  _update: =>
    # If the gutter is updated asynchronously, we need to do the same thing
    # otherwise our changes will just get reverted back.
    if @editorElement.isUpdatedSynchronously()
      @_updateSync()
    else
      atom.views.updateDocument => @_updateSync()

  _updateSync: =>
    if @editor.isDestroyed()
      return

    totalLines = @editor.getLineCount()
    currentLineNumber = if @softWrapsCount then @editor.getCursorScreenPosition().row else @editor.getCursorBufferPosition().row

    # Check if selection ends with newline
    # (The selection ends with new line because of the package vim-mode when
    # ctrl+v is pressed in visual mode)
    if @editor.getSelectedText().match(/\n$/)
      endOfLineSelected = true
    else
      currentLineNumber = currentLineNumber + 1

    lineNumberElements = @editorElement.rootElement?.querySelectorAll('.line-number')
    offset = if @startAtOne then 1 else 0
    counting_attribute = if @softWrapsCount then 'data-screen-row' else 'data-buffer-row'

    for lineNumberElement in lineNumberElements
      # "|| 0" is used given data-screen-row is undefined for the first row
      row = Number(lineNumberElement.getAttribute(counting_attribute)) ? 0

      absolute = row + 1

      relative = Math.abs(currentLineNumber - absolute)
      relativeClass = 'relative'

      if @trueNumberCurrentLine and relative is 0
        if endOfLineSelected
          relative = Number(@editor.getCursorBufferPosition().row)
        else
          relative = Number(@editor.getCursorBufferPosition().row) + 1

        relativeClass += ' current-line'
      else
        # Apply offset last thing before rendering
        relative += offset

      absoluteText = @_spacer(totalLines, absolute) + absolute
      relativeText = @_spacer(totalLines, relative) + relative

      # Keep soft-wrapped lines indicator
      if lineNumberElement.innerHTML.indexOf('•') is -1
        lineNumberElement.innerHTML = "<span class=\"absolute\">#{absoluteText}</span><span class=\"#{relativeClass}\">#{relativeText}</span><div class=\"icon-right\"></div>"

  # Undo changes to DOM
  _undo: =>
    totalLines = @editor.getLineCount()
    lineNumberElements = @editorElement.rootElement?.querySelectorAll('.line-number')
    for lineNumberElement in lineNumberElements
      row = Number(lineNumberElement.getAttribute('data-buffer-row'))
      absolute = row + 1
      absoluteText = @_spacer(totalLines, absolute) + absolute
      if lineNumberElement.innerHTML.indexOf('•') is -1
        lineNumberElement.innerHTML = "#{absoluteText}<div class=\"icon-right\"></div>"

    @lineNumberGutterElement.classList.remove('show-absolute')
