{CompositeDisposable} = require 'atom'

observeConfig = (name, fn) ->
  atom.config.observe("relative-numbers.#{name}", fn)

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @editorElement = @editor.element

    @gutter = @editor.addGutter(name: 'relative-numbers')
    @gutter.view = this

    try
      # Preferred: Subscribe to any editor model changes
      @subscriptions.add @editor.onDidChange(@update)
    catch
      # Fallback: Subscribe to initialization and editor changes
      @subscriptions.add @editorElement.onDidAttach(@update)
      @subscriptions.add @editor.onDidStopChanging(@update)

    # Subscribe for when the cursor position changes
    @subscriptions.add @editor.onDidChangeCursorPosition(@update)
    # Update when scrolling
    @subscriptions.add @editorElement.onDidChangeScrollTop(@update)

    @subscriptions.add observeConfig 'trueNumberCurrentLine', (@trueNumberCurrentLine) =>
      @update()
    @subscriptions.add observeConfig 'startAtOne', (@startAtOne) =>
      @update()
    @subscriptions.add observeConfig 'softWrapsCount', (@softWrapsCount) =>
      @update()

    @lineNumberGutterElement = atom.views.getView(@editor.gutterWithName('line-number'))
    @subscriptions.add atom.config.observe 'relative-numbers.showAbsoluteNumbers', (value) =>
      @showAbsoluteNumbers = value
      @lineNumberGutterElement.classList.toggle('show-absolute', @showAbsoluteNumbers)

  destroy: ->
    @subscriptions.dispose()
    @restoreOriginal()
    @gutter.destroy()

  formatLineNumber: (lineNumber, lineCount) ->
    maxWidth = String(lineCount).length
    width = Math.max(0, maxWidth - String(lineNumber).length)
    '&nbsp;'.repeat(width) + lineNumber

  # Update the line numbers on the editor
  update: =>
    # If the gutter is updated asynchronously, we need to do the same thing
    # otherwise our changes will just get reverted back.
    if @editorElement.isUpdatedSynchronously()
      @updateSync()
    else
      atom.views.updateDocument => @updateSync()

  updateSync: =>
    if @editor.isDestroyed()
      return

    if @softWrapsCount
      currentLineNumber = @editor.getCursorScreenPosition().row
    else
      selection = @editor.getLastSelection()
      [startRow, endRow] = selection.getBufferRowRange()
      if selection.isReversed()
        currentLineNumber = startRow
      else
        currentLineNumber = endRow

    currentLineNumber = currentLineNumber + 1

    lineNumberElements = @editorElement.rootElement?.querySelectorAll('.line-number')
    offset = if @startAtOne then 1 else 0
    attributeName = if @softWrapsCount then 'data-screen-row' else 'data-buffer-row'

    lineCount = @editor.getLineCount()
    for lineNumberElement in lineNumberElements
      row = Number(lineNumberElement.getAttribute(attributeName)) ? 0
      absolute = row + 1
      relative = Math.abs(currentLineNumber - absolute)

      relativeClass = 'relative'
      isCurrentLine = relative is 0
      relative += offset
      if isCurrentLine
        relativeClass += ' current-line'
        relative = currentLineNumber if @trueNumberCurrentLine

      absoluteText = @formatLineNumber(absolute, lineCount)
      relativeText = @formatLineNumber(relative, lineCount)

      if '.' not in lineNumberElement.innerHTML
        lineNumberElement.innerHTML = """
          <span class="absolute">#{absoluteText}</span><span class="#{relativeClass}">#{relativeText}</span><div class="icon-right"></div>
          """

  # Undo changes to DOM
  restoreOriginal: =>
    lineCount = @editor.getLineCount()
    lineNumberElements = @editorElement.rootElement?.querySelectorAll('.line-number')
    for lineNumberElement in lineNumberElements when '.' not in lineNumberElement.innerHTML
      row = Number(lineNumberElement.getAttribute('data-buffer-row'))
      absoluteText = @formatLineNumber(row + 1, lineCount)
      lineNumberElement.innerHTML = "#{absoluteText}<div class=\"icon-right\"></div>"
    @lineNumberGutterElement.classList.remove('show-absolute')
