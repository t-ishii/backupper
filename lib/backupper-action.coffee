path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs-plus'

module.exports =
class Action

  # バックアップ用パスの作成
  #
  # @param {String} cfgPath 保存先フォルダ情報
  # @return {String} savePath 保存パス
  createPath: (cfgPath=atom.config.get('backupper.sevePath')) ->

    # check dir
    if not fs.existsSync cfgPath
      # create dir
      mkdirp.sync(atom.config.get 'backupper.sevePath')

    # create /tmp/#project#file#path#name
    savePath = path.join(
      cfgPath,
      @editor.getPath().replace(
        new RegExp(path.sep, 'g'),
        '#'
      )
    )

    savePath

  # バックアップファイルへ現在のファイルを書き出し
  #
  # @param {String} savePath 保存パス
  writeFile: (savePath) ->
    ws = fs.createWriteStream savePath

    ws.on 'drain', -> console.warn 'opened file.'
    ws.on 'error', (e) -> console.error e

    ws.write @editor.getText(), @editor.getEncoding()

    ws.close()

    console.log 'saved file: '+ savePath

    return

  # 保存処理
  #
  # @param {TextEditor} editor 現在開いているテキストエディタ
  save: (@editor=atom.workspace.getActiveTextEditor()) ->

    @writeFile @createPath() if @editor? and @editor.getPath()

    return

  # リカバ処理
  #
  # @param {TextEditor} editor 現在開いているテキストエディタ
  recover: (@editor=atom.workspace.getActiveTextEditor()) ->

    if @editor? and @editor.getPath()

      # ファイル名を取得 "/" を "#" に置き換えたもの
      fileName = @editor.getPath().replace(new RegExp(path.sep, 'g'), '#')
      # 取得先パスを作成
      tmpPath = path.join(
        atom.config.get('backupper.sevePath'),
        fileName
      )

      # ファイルの存在の確認
      if fs.isFileSync tmpPath

        try
          buf = fs.readFileSync tmpPath, encoding: @editor.getEncoding()
          @editor.setText(buf.toString())

          # リカバ成功メッセージ
          atom.notifications.addSuccess(
            'backupper: recover file.'
          )

        catch
          console.error e

      else
        # バックアップファイルが存在しない場合
        atom.notifications.addInfo('backupper: no backupped.')
