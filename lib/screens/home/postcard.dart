import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String profileImage;
  final String postImage;

  const PostCard({
    super.key,
    required this.username,
    required this.profileImage,
    required this.postImage,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
            
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(widget.profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Location • 2h ago',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),


              SvgPicture.asset(
                'assets/images/3dot.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),

     
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Image.network(
            widget.postImage,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLiked = !isLiked;
                  });
                },
                child: SvgPicture.asset(
                  isLiked
                      ? 'assets/images/liked_star.svg'
                      : 'assets/images/star.svg',
                  width: 24,
                  height: 24,
                ),
              ),
              SvgPicture.asset(
                'assets/images/share.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),

       
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
          child: Text(
            'Just enjoying moments ',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
