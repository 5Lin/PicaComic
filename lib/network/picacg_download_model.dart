import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/network/request.dart';
import 'package:pica_comic/tools/io_tools.dart';
import '../base.dart';
import 'methods.dart';
import 'models.dart';
import 'dart:io';

///picacg的下载进程模型
class PicDownloadingItem extends DownloadingItem {
  PicDownloadingItem(
      this.comic,
      this.path,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,
      {super.type = DownloadType.picacg}
  );

  ///漫画模型
  final ComicItem comic;
  ///储存路径
  final String path;
  ///总共的章节数
  late final int _totalEps = comic.epsCount;
  ///正在下载的章节
  int _downloadingEps = 0;
  ///正在下载的页面
  int _index = 0;
  ///图片链接
  List<String> _urls = [];
  ///是否处于暂停状态
  bool _pauseFlag = false;
  ///章节名称
  var _eps = <String>[];
  ///已下载的页面数
  int _downloadPages = 0;
  ///重试次数
  int _retryTimes = 0;

  @override
  Map<String, dynamic> toMap()=>{
    "type": type.index,
    "comic": comic.toJson(),
    "path": path,
    "_downloadingEps": _downloadingEps,
    "_index": _index,
    "_urls": _urls,
    "_eps": _eps,
    "_downloadPages": _downloadPages,
    "id": id
  };

  PicDownloadingItem.fromMap(
    Map<String,dynamic> map,
    super.whenFinish,
    super.whenError,
    super.updateInfo,
    super.id,
    {super.type = DownloadType.picacg}):
    comic = ComicItem.fromJson(map["comic"]),
    path = map["path"],
    _downloadingEps = map["_downloadingEps"],
    _index = map["_index"],
    _urls = List<String>.from(map["_urls"]),
    _eps = List<String>.from(map["_eps"]),
    _downloadPages = map["_downloadPages"];


  ///获取各章节名称
  get eps => _eps;

  Future<void> getEps() async {
    _eps = await network.getEps(id);
  }

  Future<void> getUrls() async {
    _urls = await network.getComicContent(id, _downloadingEps);
  }

  void retry() {
    //允许重试两次
    if (_retryTimes > 2) {
      super.whenError?.call();
      _retryTimes = 0;
    } else {
      _retryTimes++;
      start();
    }
  }

  @override
  void pause() {
    notifications.endProgress();
    _pauseFlag = true;
  }

  @override
  void start() async {
    notifications.sendProgressNotification(
        _downloadPages, comic.pagesCount, "下载中", "共${downloadManager.downloading.length}项任务");
    _pauseFlag = false;
    if (_eps.isEmpty) {
      await getEps();
    }
    if (_pauseFlag) return;
    if (_eps.isEmpty) {
      super.whenError?.call(); //未能获取到章节信息调用处理错误函数
      return;
    }
    if (_downloadingEps == 0) {
      try {
        var dio = await request();
        var res = await dio.get(getImageUrl(comic.thumbUrl),
            options: Options(responseType: ResponseType.bytes));
        var file = File("$path$pathSep$id${pathSep}cover.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(res.data));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        if (_pauseFlag) return;
        //下载出错重试
        retry();
        return;
      }
      _downloadingEps++;
    }
    while (_downloadingEps <= _totalEps) {
      if (_index == _urls.length) {
        _index = 0;
      }
      if (_pauseFlag) return;
      await getUrls();
      if (_urls.isEmpty) {
        whenError?.call(); //未能获取到内容调用错误处理函数
        return;
      }
      var epPath = Directory("$path$pathSep$id$pathSep$_downloadingEps");
      await epPath.create();
      while (_index < _urls.length) {
        if (_pauseFlag) return;
        try {
          var dio = await request();
          var res = await dio.get(getImageUrl(_urls[_index]),
              options: Options(responseType: ResponseType.bytes));
          var file = File("$path$pathSep$id$pathSep$_downloadingEps$pathSep$_index.jpg");
          if (!await file.exists()) await file.create();
          await file.writeAsBytes(Uint8List.fromList(res.data));
          _index++;
          _downloadPages++;
          super.updateUi?.call();
          await super.updateInfo?.call();
          if (!_pauseFlag) {
            notifications.sendProgressNotification(_downloadPages, comic.pagesCount, "下载中",
                "共${downloadManager.downloading.length}项任务");
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          if (_pauseFlag) return;
          //下载出错重试
          retry();
          return;
        }
      }
      _downloadingEps++;
    }
    saveInfo();
    super.whenFinish?.call();
  }

  @override
  void stop() {
    _pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    file.delete(recursive: true);
  }

  ///储存漫画信息
  Future<void> saveInfo() async{
    var file = File("$path/$id/info.json");
    var downloadedItem = DownloadedComic(comic, eps, await getFolderSize(Directory("$path$pathSep$id")));
    var json = jsonEncode(downloadedItem.toJson());
    await file.writeAsString(json);
  }

  @override
  get totalPages => comic.pagesCount;

  @override
  get downloadedPages => _downloadPages;

  @override
  get cover => comic.thumbUrl;

  @override
  String get title => comic.title;
}
