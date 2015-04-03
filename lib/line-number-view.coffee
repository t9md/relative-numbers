{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorView = atom.views.getView(@editor)
    @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')

    # Subscribe for when the line numbers should be updated.
    @subscriptions.add(@editor.onDidChangeCursorPosition(@_update))
    @subscriptions.add(@editor.onDidStopChanging(@_update))

    # Subscribe to twhen the true number on current line config is modified.
    @subscriptions.add atom.config.onDidChange 'relative-line-numbers.trueNumberCurrentLine', =>
      @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')
      @_update()

   # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_update()

  # Update the line numbers on the editor
  _update: () =>
    totalLines = @editor.getLineCount()
    currentLineNumber = @editor.getCursorScreenPosition().row + 1
    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')

    index = @_index(totalLines, currentLineNumber)

    for lineNumberElement in lineNumberElements
      row = lineNumberElement.getAttribute('data-buffer-row')
      relative = index[row] or = 0
      lineNumberElement.innerHTML = "#{relative}<div class=\"icon-right\"></div>"

  # Return a lookup  array with the relative line numbers
  _index: (totalLines, currentLineNumber) ->
    for line in [0...totalLines]
      lineNumber = (Math.abs(currentLineNumber - (line + 1)))
      if @trueNumberCurrentLine and lineNumber == 0
        currentLineNumber
      else
        lineNumber
