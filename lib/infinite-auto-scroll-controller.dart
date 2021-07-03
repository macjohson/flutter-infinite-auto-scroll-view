part of infinite_auto_scroll_view;

class _OriginDataItem<T> {
  final int index;
  final T data;
  bool active;

  _OriginDataItem(
      {required this.index, required this.data, this.active = false});
}

/// 无限循环列表控制器
class InfiniteAutoScrollController<T> {
  /// 动画控制器
  final AnimationController _animationController;
  /// 列表项高度
  final double itemExtend;
  /// 列表项构建函数
  final Widget Function(T item,bool active, int index) itemBuild;
  /// 是否自动播放
  final bool autoPlay;
  Timer? _timer;
  /// 每项的滚动时间
  final Duration perItemDuration;
  /// 列表项总数，可直接更新，用于异步加载，比如page游标
  int? total;
  /// 加载更多的回调函数，用于异步更新， 当有更多异步数据需要加载时，此项必须传入
  final Future<List<T>> Function()? onLoadMore;



  /// 当前渲染的数据
  List<_OriginDataItem<T>> _currentPageData = [];

  /// 列表可视区域高度
  double? _viewHeight;

  /// 每次渲染多少条数据
  int _perPageCount = 0;

  /// 原始数据
  List<_OriginDataItem<T>> _originData = [];

  /// 当前光标的位置，当自动播放时，光标不存在
  int? cursorIndex;

  /// 加载更多标识
  bool _loadMoreLoading = false;

  InfiniteAutoScrollController(
      {required TickerProvider vsync,
      required this.perItemDuration,
      required this.itemExtend,
      required this.itemBuild,
      this.autoPlay = true, this.total, this.onLoadMore})
      : _animationController =
            AnimationController(vsync: vsync, duration: perItemDuration)
              ..drive(CurveTween(curve: Curves.linear));

  /// 用于更新列表
  final StreamController<List<Widget>> _streamController = StreamController();

  /// 销毁，必须调用
  dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _streamController.close();
  }

  Future<double> get _viewHeightFuture {
    _timer?.cancel();

    final Completer<double> completer = Completer();

    if (_viewHeight != null) {
      completer.complete(_viewHeight);
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_viewHeight != null) {
          completer.complete(_viewHeight);
        }
      });
    }

    return completer.future;
  }

  ///通过此接口更新数据
  Future<void> setData(List<T> data) async {
    _originData = List.generate(data.length,
        (index) => _OriginDataItem(index: index, data: data[index]));
    final __viewHeight = await _viewHeightFuture;
    _perPageCount = ((__viewHeight / itemExtend != 0
                ? __viewHeight ~/ itemExtend
                : __viewHeight / itemExtend) +
            3)
        .toInt();

    _initFirstPageData();

    await Future.delayed(const Duration(milliseconds: 50));

    _animationController.reset();

    if (autoPlay) {
      play();
    }
  }

  /// 更新列表
  _updateList(List<_OriginDataItem<T>> list) {
    _currentPageData = list;
    final List<Widget> widgets = List.generate(list.length, (index) {
      final item = list[index];
      return itemBuild(item.data,item.active, index);
    });
    _streamController.sink.add(widgets);
  }

  /// 初始化第一屏的数据
  void _initFirstPageData() {
    final firstPageData = _originData
        .getRange(
            0,
            _perPageCount > _originData.length
                ? _originData.length
                : _perPageCount)
        .toList();
    _updateList(firstPageData);
  }

  /// 播放
  /// 当[loop]为true时自动播放
  /// 当[cursor]参数仅供[next]使用
  play({bool loop = true, cursor = false}) {
    if(_loadMoreLoading) return;
    /*
    * 未达到自动循环滚屏
    * 移动光标
    * */
    if(_perPageCount - 3 > _originData.length && _originData.isNotEmpty){
      if(cursor){
        if(cursorIndex == null){
         cursorIndex = 0;
        }else{
          if(cursorIndex! < _originData.length - 1){
            cursorIndex = cursorIndex! + 1;
          }else{
            cursorIndex = 0;
          }
        }

        _currentPageData = List.generate(_currentPageData.length, (index){
          final item  = _currentPageData[index];
          if(index == cursorIndex){
            item.active = true;
          }else{
            item.active = false;
          }

          return item;
        });

        _updateList(_currentPageData);
      }else{
        _currentPageData = List.generate(_currentPageData.length, (index){
          final item  = _currentPageData[index];
          item.active = false;
          return item;
        });

        _updateList(_currentPageData);
      }
    }

    /**
     * 未达到滚屏要求不启动播放
     */
    if (_perPageCount - 3 > _originData.length || _originData.isEmpty) return;

    if (loop) {
      _animationController.duration = perItemDuration;
    }

    if(cursor){
      final activeIndex = _currentPageData.length ~/ 2  + 1;
      cursorIndex = activeIndex;
      _currentPageData = List.generate(_currentPageData.length, (index){
        final item  = _currentPageData[index];
        if(index == activeIndex){
          item.active = true;
        }else{
          item.active = false;
        }

        return item;
      });

      _updateList(_currentPageData);
    }else{
      _currentPageData = _currentPageData.map((e){
        e.active = false;
        return e;
      }).toList();

      _updateList(_currentPageData);
      cursorIndex = null;
    }
    _animationController.forward().whenComplete(() {
      final current = !cursor ? _currentPageData.map((e) {
        e.active = false;
        return e;
      }).toList() : [..._currentPageData];

      current.removeAt(0);
      int pathIndex = current.last.index;
      if (pathIndex < _originData.length - 1) {
        pathIndex++;
      } else {
        pathIndex = 0;
      }

      current.add(_originData[pathIndex]);

      _updateList(current);

      _animationController.reset();

      if(current.last.index == _originData.length - 1 && total != null && _originData.length < total! && onLoadMore != null){
        _loadMoreLoading = true;
        onLoadMore!().then((value){
          _loadMoreLoading = false;
          final List<_OriginDataItem<T>> addList = List.generate(value.length, (index) => _OriginDataItem(index: index, data: value[index]));
          _originData.addAll(addList);

          if(loop){
            play();
          }
        });
      }else{
        if (loop) {
          play();
        }
      }
    });
  }

  /// 暂停
  pause() {
    _animationController.stop();
  }

  /// 下一项
  /// [cursor]为true表示光标下移
  next({bool cursor =false}) {
    pause();
    _animationController.duration = Duration(milliseconds: 225);
    play(loop: false, cursor: cursor);
  }

  /// 上一项
  /// [cursor]为true表示光标上移
  pre({bool cursor = false}) {
    if(_perPageCount - 3 > _originData.length || _originData.isNotEmpty){
      if(cursor){
        if(cursorIndex == null){
          cursorIndex = _originData.length - 1;
        }else{
          if(cursorIndex! != 0){
            cursorIndex = cursorIndex! - 1;
          }else{
            cursorIndex = _originData.length - 1;
          }
        }

        _currentPageData = List.generate(_currentPageData.length, (index){
          final item  = _currentPageData[index];
          if(index == cursorIndex){
            item.active = true;
          }else{
            item.active = false;
          }

          return item;
        });

        _updateList(_currentPageData);
      }
    }
    if (_perPageCount - 3 > _originData.length || _originData.isEmpty) return;
    pause();
    _animationController.duration = Duration(milliseconds: 225);
    List<_OriginDataItem<T>> current = _currentPageData.map((e) {
      e.active = false;
      return e;
    }).toList();

    current.removeLast();

    int pathIndex = current.first.index;

    if (pathIndex == 0) {
      pathIndex = _originData.length - 1;
    } else {
      pathIndex--;
    }

    current = [_originData[pathIndex], ...current];
    if (cursor) {
      cursorIndex = current.length ~/ 2;
      current[current.length ~/ 2].active = true;
    }else{
      cursorIndex = null;
    }

    _updateList(current);

    _animationController.reset();
    _animationController.reverse(from: 1);
  }
}
