{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorView = atom.views.getView(@editor)
    @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')
    @showNormalLineNumbers = atom.config.get('relative-line-numbers.showNormalLineNumbers')

    # Subscribe for when the line numbers should be updated.
    @subscriptions.add(@editor.onDidChangeCursorPosition(@_update))
    @subscriptions.add(@editor.onDidStopChanging(@_update))

    # Subscribe to when the true number on current line config is modified.
    @subscriptions.add atom.config.onDidChange 'relative-line-numbers.trueNumberCurrentLine', =>
      @trueNumberCurrentLine = atom.config.get('relative-line-numbers.trueNumberCurrentLine')
      @_update()

    # Subscribe to when the show normal line numbers config is modified.
    @subscriptions.add atom.config.onDidChange 'relative-line-numbers.showNormalLineNumbers', =>
      @showNormalLineNumbers = atom.config.get('relative-line-numbers.showNormalLineNumbers')
      @_update()

   # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_update()

  _spacer: (totalLines, currentIndex) ->
    Array(totalLines.toString().length - currentIndex.toString().length + 1).join ' '

  # Update the line numbers on the editor
  _update: () =>
    totalLines = @editor.getLineCount()
    currentLineNumber = @editor.getCursorScreenPosition().row + 1
    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')

    index = @_index(totalLines, currentLineNumber)

    for lineNumberElement in lineNumberElements
      row = lineNumberElement.getAttribute('data-buffer-row')
      relative = index[row] or = 0
      normalLineNumbers = ''
      if @showNormalLineNumbers
        humanRow = parseInt(row) + 1
        normalLineNumbers = humanRow + @_spacer(totalLines, humanRow) + " "
      lineNumberElement.innerHTML = "#{normalLineNumbers}#{relative}<div class=\"icon-right\"></div>"

  # Return a lookup  array with the relative line numbers
  _index: (totalLines, currentLineNumber) ->
    for line in [0...totalLines]
      lineNumber = (Math.abs(currentLineNumber - (line + 1)))
      if @trueNumberCurrentLine and lineNumber == 0
        if @showNormalLineNumbers
          '•'
        else
          currentLineNumber
      else
        lineNumber
