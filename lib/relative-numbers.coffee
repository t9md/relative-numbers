LineNumberView = require './line-number-view'
{CompositeDisposable} = require 'atom'

module.exports =
  # Config schema
  config:
    trueNumberCurrentLine:
      order: 0
      type: 'boolean'
      default: true
      description: 'Show the true number on the current line'
    showAbsoluteNumbers:
      order: 1
      type: 'boolean'
      default: false
      description: 'Show absolute line numbers too?'
    startAtOne:
      order: 2
      type: 'boolean'
      default: false
      description: 'Start relative line numbering at one'
    softWrapsCount:
      order: 3
      type: 'boolean'
      default: true
      description: 'Do soft-wrapped lines count? (No in vim-mode-plus, yes in vim-mode)'

  subscriptions: null
  activate: ->
    commandsDisposer = atom.workspace.observeTextEditors (editor) ->
      if not editor.gutterWithName('relative-numbers')
        new LineNumberView(editor)

  deactivate: ->
    commandsDisposer?.dispose()
    for editor in atom.workspace.getTextEditors()
      editor.gutterWithName('relative-numbers').view?.destroy()
