path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs-plus'
jschardet = require 'jschardet'

module.exports =
class Action

  # ファイル名禁止文字の変換処理
  #
  # @param {String} filePath
  # @return {String} 変換後のファイル名
  convertPath = (filePath) ->
    filePath.replace /[\/\\:\*\?"\<\>\|]/g, '#'

  # エンコーディング取得処理
  #
  # @param {String} content ファイル内容
  # @return {String} encoding エンコーディング
  getEncoding = (content) ->
    {encoding} = jschardet.detect content
    encoding = 'utf8' if encoding is 'ascii'
    encoding

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
      convertPath @editor.getPath()
    )

    savePath

  # バックアップファイルへ現在のファイルを書き出し
  #
  # @param {String} savePath 保存パス
  writeFile: (savePath) ->
    ws = fs.createWriteStream savePath

    ws.on 'drain', -> console.warn 'opened file.'
    ws.on 'error', (e) -> console.error e

    text = @editor.getText()

    encoding = getEncoding text

    ws.write text, encoding

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
      fileName = convertPath @editor.getPath()
      # 取得先パスを作成
      tmpPath = path.join(
        atom.config.get('backupper.sevePath'),
        fileName
      )

      # ファイルの存在の確認
      if fs.isFileSync tmpPath

        try

          encoding = getEncoding @editor.getText()

          buf = fs.readFileSync tmpPath, encoding: encoding
          @editor.setText(buf.toString())

          # リカバ成功メッセージ
          atom.notifications.addSuccess(
            'backupper: recover file.'
          )

        catch e
          console.error e

      else
        # バックアップファイルが存在しない場合
        atom.notifications.addInfo('backupper: no backupped.')
