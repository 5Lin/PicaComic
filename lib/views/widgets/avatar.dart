import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_user_info.dart';
import '../../base.dart';


class Avatar extends StatelessWidget {
  const Avatar({Key? key,
    required this.size,
    this.avatarUrl,
    this.frame,
    this.couldBeShown=false,
    this.name = "",
    this.slogan,
    this.level = 0
  }) : super(key: key);
  final double size;
  final String? avatarUrl;
  final String? frame;
  final bool couldBeShown;
  final String name;
  final String? slogan;
  final int level;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        if(couldBeShown){
          showUserInfo(context, avatarUrl, frame, name, slogan, level);
        }
      },
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(size)),
        child: Stack(
          children: [
            Positioned(
              top: size*0.25/2,
              left: size*0.25/2,
              child: Container(
                width: size*0.75,
                height: size*0.75,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(size)),
                child: (avatarUrl==null || avatarUrl=="DEFAULT AVATAR URL")?const Image(image: AssetImage("images/avatar_small.png"),fit: BoxFit.cover,):CachedNetworkImage(
                  imageUrl: getImageUrl(avatarUrl!),
                  fit: BoxFit.cover,
                  errorWidget: (context,s,d)=>const Center(child: Icon(Icons.error),),
                  placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
                  filterQuality: FilterQuality.medium
                ),
              ),
            ),
            if(frame!=null&&appdata.settings[5]=="1")
              Positioned(
                child: CachedNetworkImage(
                  imageUrl: getImageUrl(frame!),
                  errorWidget: (context,s,d){return const SizedBox();},
                ),
              ),
          ],
        ),
      ),
    );
  }
}
