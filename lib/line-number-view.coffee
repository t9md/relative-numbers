{CompositeDisposable} = require 'atom'

module.exports =
class LineNumberView
  constructor: (@editor) ->
    @subscriptions = new CompositeDisposable()
    @editorView = atom.views.getView(@editor)
    @trueNumberCurrentLine = atom.config.get('relative-numbers.trueNumberCurrentLine')

    # Subscribe for when the line numbers should be updated.
    @subscriptions.add(@editor.onDidChangeCursorPosition(@_update))
    @subscriptions.add(@editor.onDidStopChanging(@_update))

    # Subscribe to when the true number on current line config is modified.
    @subscriptions.add atom.config.onDidChange 'relative-numbers.trueNumberCurrentLine', =>
      @trueNumberCurrentLine = atom.config.get('relative-numbers.trueNumberCurrentLine')
      @_update()

    # Dispose the subscriptions when the editor is destroyed.
    @subscriptions.add @editor.onDidDestroy =>
      @subscriptions.dispose()

    @_update()

  _spacer: (totalLines, currentIndex) ->
    Array(totalLines.toString().length - currentIndex.toString().length + 1).join '&nbsp;'

  # Update the line numbers on the editor
  _update: () =>
    totalLines = @editor.getLineCount()
    currentLineNumber = Number(@editor.getCursorBufferPosition().row) + 1
    lineNumberElements = @editorView.rootElement?.querySelectorAll('.line-number')

    for lineNumberElement in lineNumberElements
      row = Number(lineNumberElement.getAttribute('data-buffer-row'))
      relativeNumber = (Math.abs(currentLineNumber - (row + 1)))
      relativeText = relativeNumber.toString()
      if @trueNumberCurrentLine and relativeNumber == 0
        relativeNumber = currentLineNumber
        relativeText = '<span class="relative-current-line">' + currentLineNumber + '</span>'
      relativeText = @_spacer(totalLines, relativeNumber) + relativeText

      # Keep soft-wrapped lines indicator
      if lineNumberElement.innerHTML.indexOf('•') == -1
        lineNumberElement.innerHTML = "#{relativeText}<div class=\"icon-right\"></div>"
