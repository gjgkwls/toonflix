import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toonflix/models/webtoon_detail_model.dart';
import 'package:toonflix/models/webtoon_episode_model.dart';
import 'package:toonflix/services/api_service.dart';
import 'package:toonflix/widgets/episode_widget.dart';

class DetailScreen extends StatefulWidget {
  final String title, thumb, id;

  const DetailScreen({
    super.key,
    required this.title,
    required this.thumb,
    required this.id,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<WebtoonDetailModel> webtoon;
  late Future<List<WebtoonEpsideModel>> episodes;

  late SharedPreferences prefs;

  bool isLiked = false;
  List<String>? likedToons;

  Future initPrefs() async {
    prefs = await SharedPreferences
        .getInstance(); // getInstance메소드가 Future라서 async, await 해야해
    likedToons = prefs.getStringList('likedToons');
    print("likedToons : $likedToons");

    if (likedToons != null) {
      if (likedToons!.contains(widget.id) == true) {
        setState(() {
          isLiked = true;
        });
      }
    } else {
      await prefs.setStringList('likedToons', []);
      likedToons = prefs.getStringList('likedToons');
    }
  }

  // initState 메소드는 StatelessWidget에서는 사용 못하고 StatefulWidget에서 사용가능
  @override
  void initState() {
    // 초기화하고자 하는 데이터가 생성자에서는 하기 힘들다면 여기서~!
    super.initState();

    // HomeScreen에서는 생성과 초기화를 한번에 진행함.
    // 근데 여기서는 id라는 파라미터가 필요한데 위에서는 그게 안돼... 그래서...
    // 여기서 해... (나도 이해가 100%되진않음)
    webtoon = ApiService.getToonById(widget.id);
    episodes = ApiService.getLatestEpisodeById(widget.id);
    initPrefs();
  }

  onHeartTap() async {
    print("잉");
    if (isLiked) {
      likedToons!.remove(widget.id);
    } else {
      print("자자");
      likedToons!.add(widget.id);
    }

    print("클릭했을 때 $likedToons");
    await prefs.setStringList('likedToons', likedToons!);
    setState(() {
      isLiked = !isLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: onHeartTap,
            icon: Icon(isLiked
                ? Icons.favorite_outlined
                : Icons.favorite_border_outlined),
          ),
        ],
        title: Text(
          widget
              .title, // 여기에 있는 widget이 의미하는건 State가 속한 StatefulWidget (여기선 즉, 부모 위젯인 DetailScreen)
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: widget.id,
                    child: Container(
                      width: 250,
                      clipBehavior: Clip.hardEdge, // 부모가 자식영역 침범하는구
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 15,
                                offset: const Offset(10, 10),
                                color: Colors.black.withOpacity(0.8)),
                          ]),
                      child: Image.network(
                        widget.thumb,
                        headers: const {
                          "User-Agent":
                              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder(
                future: webtoon,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data!.about,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          "${snapshot.data!.age} / ${snapshot.data!.genre}",
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );
                  }
                  return const Text("..."); // 이건 일종의 인디게이터
                },
              ),
              const SizedBox(
                height: 50,
              ),
              FutureBuilder(
                future: episodes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        for (var episode in snapshot.data!)
                          Episode(
                            episode: episode,
                            webtoonId: widget.id,
                          )
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
