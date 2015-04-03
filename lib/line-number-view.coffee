{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorView = atom.views.getView(@editor)
    @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')

    @subscriptions.add(@editor.onDidChangeCursorPosition(@_calculate))
    @subscriptions.add(@editor.onDidStopChanging(@_calculate))

    @subscriptions.add atom.config.onDidChange 'relative-line-numbers.trueNumberCurrentLine', =>
      @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')
      @_calculate()

    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_calculate()

  _calculate: () =>
    totalLines = @editor.getLineCount()
    currentLineNumber = @editor.getCursorScreenPosition().row + 1
    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')

    index = @_index(totalLines, currentLineNumber)

    for lineNumberElement in lineNumberElements
      row = lineNumberElement.getAttribute('data-buffer-row')
      relative = index[row] or = 0
      lineNumberElement.innerHTML = "#{relative}<div class=\"icon-right\"></div>"

  _index: (totalLines, currentLineNumber) ->
    for line in [0...totalLines]
      lineNumber = (Math.abs(currentLineNumber - (line + 1)))
      if @trueNumberCurrentLine and lineNumber == 0
        currentLineNumber
      else
        lineNumber
