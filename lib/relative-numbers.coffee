LineNumberView = require './line-number-view'

module.exports =
  # Config schema
  config:
    trueNumberCurrentLine:
      type: 'boolean'
      default: true
      description: 'Show the true number on the current line'

  configDefaults:
    trueNumberCurrentLine: true

  activate: (state) ->
    console.log('Activating relative line numbers.');
    atom.workspace.observeTextEditors (editor) ->
      new LineNumberView(editor)

  deactivate: () ->
