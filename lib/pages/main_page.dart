import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {

  final http.Client? client;
  MainPage({
    Key? key, this.client,
  }) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;
   @override
  void initState() {
    super.initState();
    bloc = MainBloc(client: widget.client);
    }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SafeArea(
          child: MainPageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatefulWidget {
  @override
  _MainPageContentState createState() => _MainPageContentState();
}



class _MainPageContentState extends State<MainPageContent> {
  late final FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      myFocusNode.addListener(() {
        setState(() {
          print("ChangeState in Focus node");

        });
      });

    });

  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
          return Stack(
      children: [
        MainPageStateWidget(focusNode: myFocusNode),
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
          ),
          child: SearchWidget(focusNode: myFocusNode),
        ),
      ],
    );
  }
}

class SearchWidget extends StatefulWidget {
  final FocusNode focusNode;
  const SearchWidget({Key? key, required this.focusNode}) : super(key: key);
  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      controller.addListener(() {
        bloc.updateText(controller.text);

        if(bloc.changedText)
          setState(() {
            print("Rebuild widget");

      });});
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.focusNode,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      cursorWidth: 2,
      cursorColor: Colors.white,
      controller: controller,
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 20,
        color: Colors.white,
      ),
      decoration:  InputDecoration(
          filled: true,
          fillColor: SuperheroesColors.indigo75,
          focusColor: Colors.white,
          isDense: true,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white54,
            size: 24,
          ),
          suffix: GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: Icon(
                Icons.clear,
                color: Colors.white,
              )
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white, width: 2,)
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder:

          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:  (controller.text != "") ?
            BorderSide(color: Colors.white, width: 2,) :
            BorderSide(color: Colors.white24),
          ),


      ),
    );
  }
  @override
  void dispose() {
   // _myFocusNode.dispose();
    super.dispose();

  }
}

class MainPageStateWidget extends StatelessWidget {
  final FocusNode focusNode;

  MainPageStateWidget({Key? key, required this.focusNode}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return SizedBox();
        }
        final MainPageState state = snapshot.data!;
        switch (state) {
          case MainPageState.loading:
            return LoadingIndicator();
          case MainPageState.minSymbols:
            return MinSymbolsWidget();
          case MainPageState.noFavorites:
            return Stack(children: [
              NoFavoritesWidget(focusNode: focusNode),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ActionButton(text: "Remove", onTap: () => bloc.removeFavorite())
                ),
              )
              ],
            );


          case MainPageState.favorites:
            return Stack(
                children: [SuperheroesList(
                  title: "Your favorites",
                  stream: bloc.observeFavoriteSuperheroes(),
                ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ActionButton(text: "Remove", onTap: () => bloc.removeFavorite())),
                  ),
                ]
            );
          case MainPageState.searchResults:
            return SuperheroesList(
              title: "Search results",
              stream: bloc.observedSearchedSuperheroes(),
            );
          case MainPageState.nothingFound:
            return NothingFoundWidget(focusNode: focusNode);
          case MainPageState.loadingError:
            return LoadingErrorWidget();
          default:
            return Center(
                child: Text(
              snapshot.data!.toString(),
              style: TextStyle(color: Colors.white),
            ));
        }
      },
    );
  }
}

class LoadingErrorWidget extends StatelessWidget {

  const LoadingErrorWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InfoWithButton(
      title: "Error happened",
      subtitle: "Please, try again",
      buttonText: "Retry",
      assetImage: SuperheroesImages.supernman,
      imageHeight: 106,
      imageWidth: 126,
      imageTopPadding: 22, onTap: () {

    },
    );
  }
}

class NoFavoritesWidget extends StatefulWidget {
  final FocusNode focusNode;

  const NoFavoritesWidget({Key? key, required this.focusNode}) : super(key: key);

  @override
  _NoFavoritesWidgetState createState() => _NoFavoritesWidgetState();
}

class _NoFavoritesWidgetState extends State<NoFavoritesWidget> {
      @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoWithButton(
        title: "No favorites yet",
        subtitle: "Search and add",
        buttonText: "Search",
        assetImage: SuperheroesImages.ironman,
        imageHeight: 119,
        imageWidth: 108,
        imageTopPadding: 9,

        onTap: () {
            print("Tap search");
            widget.focusNode.requestFocus();
            },
      ),
    );
  }
}

class NothingFoundWidget extends StatefulWidget {
  final FocusNode focusNode;

  const NothingFoundWidget({Key? key, required this.focusNode}) : super(key: key);

  @override
  _NothingFoundWidgetState createState() => _NothingFoundWidgetState();
}

class _NothingFoundWidgetState extends State<NothingFoundWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: InfoWithButton(
          title: "Nothing found",
          subtitle: "Search for something else",
          buttonText: "Search",
          assetImage: SuperheroesImages.hulk,
          imageHeight: 112,
          imageWidth: 84,
          imageTopPadding: 16,
          onTap: () {
            print("Tap search");
                         widget.focusNode.requestFocus();
            },
        ),
    );
  }
}

class SuperheroesList extends StatelessWidget {
  final String title;
  final Stream<List<SuperheroInfo>> stream;

  const SuperheroesList({
    Key? key,
    required this.title,
    required this.stream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuperheroInfo>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final List<SuperheroInfo> superheroes = snapshot.data!;
          return ListView.separated(
            physics: BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: superheroes.length + 1,
            itemBuilder: (
                BuildContext context, int index){
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 90, bottom: 12,),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              final SuperheroInfo item = superheroes[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SuperheroCard(
                  superheroInfo: item,

                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SuperheroPage(name: item.name),
                      ),
                    );
                  },
                ),
              );
            }, separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 8,);
          },
          );
        });
  }
}


class MinSymbolsWidget extends StatelessWidget {
  const MinSymbolsWidget({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: 110,
          left: 16,
          right: 16,
        ),
        child: Text(
          "Enter at least 3 symbols",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
