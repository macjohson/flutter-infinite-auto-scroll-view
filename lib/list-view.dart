part of infinite_auto_scroll_view;

class _ListView extends StatelessWidget {
  final InfiniteAutoScrollController infiniteAutoScrollController;
  const _ListView({Key? key, required this.infiniteAutoScrollController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Widget>>(
      builder: (BuildContext context, AsyncSnapshot<List<Widget>> snapshot) {
        if (infiniteAutoScrollController._perPageCount != 0) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                  top: infiniteAutoScrollController._perPageCount - 3 >
                          infiniteAutoScrollController._originData.length
                      ? 0
                      : -infiniteAutoScrollController.itemExtend,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data ?? [],
                  ))
            ],
          );
        }
        return Container();
      },
      initialData: [],
      stream: infiniteAutoScrollController._streamController.stream,
    );
  }
}
