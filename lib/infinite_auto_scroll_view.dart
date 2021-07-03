/// 无限循环列表，可自动滚动、暂停和手动控制滚动，或者以光标方式选择项目
/// 主要用于远程遥控列表，列表的控制只能通过[InfiniteAutoScrollController]来完成
/// 刷新数据使用[InfiniteAutoScrollController.setData]来完成
/// 光标的实现通过[InfiniteAutoScrollController.itemBuild]构建，函数中的[active]参数表示当前光标是否处于此项
library infinite_auto_scroll_view;

import 'dart:async';

import 'package:flutter/material.dart';

part 'infinite-auto-scroll-controller.dart';
part 'list-view.dart';

class InfiniteAutoScrollView extends StatelessWidget {
  final InfiniteAutoScrollController infiniteAutoScrollController;
  const InfiniteAutoScrollView(
      {Key? key, required this.infiniteAutoScrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(!constraints.hasInfiniteHeight);
        if (infiniteAutoScrollController._viewHeight == null) {
          infiniteAutoScrollController._viewHeight = constraints.biggest.height;
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: infiniteAutoScrollController._animationController,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(
                    0,
                    -infiniteAutoScrollController.itemExtend *
                        infiniteAutoScrollController._animationController.value),
                child: child,
              );
            },
            child: _ListView(
                infiniteAutoScrollController: infiniteAutoScrollController
            ),
          ),
        );
      },
    );
  }
}
