path = require 'path'
mkdirp = require 'mkdirp'
fs = require 'fs-plus'
iconv = require 'iconv-lite'
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
  # @param {Buffer} buffer ファイル内容
  # @return {String} encoding エンコーディング
  getEncoding = (buffer) ->
    {encoding} = jschardet.detect(buffer) ? { encoding: null }
    encoding = stripEncName(encoding) if encoding?
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

  # Strip symbols from encoding name
  #
  # @return {String}
  stripEncName = (name) ->
    name.toLowerCase().replace(/[^0-9a-z]|:\d{4}$/g, '')

  # バックアップファイルへ現在のファイルを書き出し
  #
  # @param {String} savePath 保存パス
  writeFile: (savePath) ->

    fs.readFile @editor.getPath(), (error, buffer) =>
      return if error? or not @editor?
      encoding = getEncoding buffer
      if iconv.encodingExists(encoding)
        fs.writeFile(savePath, iconv.decode(buffer, encoding), encoding='utf8', (err) ->
          if err?
            console.error err
          else
            console.log 'saved file: '+ savePath
        )

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

          buf = fs.readFileSync tmpPath, encoding: 'utf8'
          @editor.setText(buf)

          # リカバ成功メッセージ
          atom.notifications.addSuccess('backupper: recover file.')

        catch e
          console.error e

      else
        # バックアップファイルが存在しない場合
        atom.notifications.addInfo('backupper: no backupped.')
