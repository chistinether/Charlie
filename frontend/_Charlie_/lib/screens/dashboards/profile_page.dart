import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/test_users.dart';

import '../../services/local_storage_service.dart';
import '../../services/firebase_service.dart';

import '../features/documents_screen.dart';
import '../features/help_and_support_screen.dart';
import '../features/about_charlie_screen.dart';
import '../features/budget_notification_screen.dart';
import '../features/voice_settings_screen.dart';
import '../../providers/theme_provider.dart';

import '../login_screen.dart';



class ProfilePage extends StatefulWidget {

  final TestUser user;


  const ProfilePage({

    super.key,

    required this.user,

  });



  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  final ImagePicker _picker = ImagePicker();

  Uint8List? _photoBytes;

  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();

    _photoBytes = widget.user.photoBytes;

    // If we don't already have the photo in memory (e.g. app was just
    // restarted), try loading it back from local storage.
    if (_photoBytes == null) {
      _loadSavedPhoto();
    }
  }

  Future<void> _loadSavedPhoto() async {
    final saved = await LocalStorageService.loadPhoto(widget.user.email);

    if (!mounted || saved == null) return;

    setState(() {
      _photoBytes = saved;
    });

    widget.user.photoBytes = saved;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) return;

      // Show the picked photo immediately, then save it locally so it
      // survives navigating away, logging out/in, and app restarts.
      setState(() {
        _photoBytes = bytes;
        _uploadingPhoto = true;
      });

      widget.user.photoBytes = bytes;

      try {
        await LocalStorageService.savePhoto(widget.user.email, bytes);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Photo updated, but couldn't be saved: $e",
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _uploadingPhoto = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not update photo: $e")),
      );
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Take a photo"),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),


      appBar: AppBar(

        backgroundColor: const Color(0xFF2E7D32),

        elevation: 0,

        title: const Text(

          "Profile",

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

          ),

        ),

      ),



      body: SingleChildScrollView(

        child: Column(

          children: [


            const SizedBox(height:30),



            GestureDetector(

              onTap: _showPhotoOptions,

              child: Stack(

                children: [

                  CircleAvatar(

                    radius:55,

                    backgroundColor: const Color(0xFF2E7D32),

                    backgroundImage: _photoBytes != null
                        ? MemoryImage(_photoBytes!) as ImageProvider
                        : null,

                    child: _photoBytes == null
                        ? const Icon(
                            Icons.person,
                            size:60,
                            color:Colors.white,
                          )
                        : null,

                  ),

                  if (_uploadingPhoto)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  Positioned(

                    bottom: 0,

                    right: 0,

                    child: Container(

                      padding: const EdgeInsets.all(6),

                      decoration: const BoxDecoration(

                        color: Color(0xFF2E7D32),

                        shape: BoxShape.circle,

                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),

                      ),

                      child: const Icon(

                        Icons.camera_alt,

                        size: 18,

                        color: Colors.white,

                      ),

                    ),

                  ),

                ],

              ),

            ),



            const SizedBox(height:15),



            Text(

              widget.user.name,

              style: const TextStyle(

                fontSize:24,

                fontWeight:FontWeight.bold,

              ),

            ),



            const SizedBox(height:5),



            Text(

              widget.user.email,

              style: const TextStyle(

                color:Colors.grey,

                fontSize:16,

              ),

            ),



            const SizedBox(height:30),



            Card(

              margin: const EdgeInsets.symmetric(horizontal:20),

              shape: RoundedRectangleBorder(

                borderRadius:BorderRadius.circular(18),

              ),


              child: Padding(

                padding:const EdgeInsets.all(18),


                child:Column(

                  children:[


                    profileTile(
                      Icons.school,
                      "University",
                      widget.user.university,
                    ),


                    const Divider(),



                    profileTile(
                      Icons.menu_book,
                      "Course",
                      widget.user.course,
                    ),



                    const Divider(),



                    profileTile(
                      Icons.calendar_today,
                      "Year of Study",
                      "Year ${widget.user.year}",
                    ),



                    const Divider(),



                    profileTile(
                      Icons.phone,
                      "Phone",
                      widget.user.phone,
                    ),


                  ],

                ),

              ),

            ),



            const SizedBox(height:30),



            const Padding(

              padding:EdgeInsets.symmetric(horizontal:20),

              child:Align(

                alignment:Alignment.centerLeft,

                child:Text(

                  "Settings",

                  style:TextStyle(

                    fontSize:22,

                    fontWeight:FontWeight.bold,

                  ),

                ),

              ),

            ),



            const SizedBox(height:15),


                        settingsTile(

                          Icons.dark_mode,

                          "Dark Mode",

                          () {},

                          trailing: ValueListenableBuilder<bool>(

                            valueListenable:
                            ThemeProvider.isDarkMode,


                            builder:(context,isDark,child){


                              return Switch(

                                value:isDark,


                                activeColor:
                                const Color(0xFF2E7D32),


                                onChanged:(value){


                                  ThemeProvider.toggleTheme(value);


                                },

                              );


                            },

                          ),

                        ),


            settingsTile(


              Icons.notifications,

              "Notifications",

              (){

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        BudgetNotificationsScreen(

                          user:widget.user,

                        ),

                  ),

                );

              },

            ),



            settingsTile(

              Icons.record_voice_over,

              "Voice Settings",

              (){

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        const VoiceSettingsScreen(),

                  ),

                );

              },

            ),





            settingsTile(

              Icons.description,

              "Financial Documents",

              (){

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        DocumentsScreen(userEmail: widget.user.email),

                  ),

                );

              },

            ),





            settingsTile(

              Icons.help_outline,

              "Help & Support",

              (){

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        const HelpSupportScreen(),

                  ),

                );

              },

            ),





            settingsTile(

              Icons.info_outline,

              "About Charlie",

              (){

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder:(context)=>

                        const AboutCharlieScreen(),

                  ),

                );

              },

            ),






            settingsTile(

              Icons.logout,

              "Logout",

              (){

                showDialog(

                  context:context,

                  builder:(context)=>AlertDialog(

                    title:const Text("Logout"),

                    content:const Text(

                      "Are you sure you want to logout?",

                    ),


                    actions:[


                      TextButton(

                        onPressed:(){

                          Navigator.pop(context);

                        },

                        child:const Text("Cancel"),

                      ),



                      ElevatedButton(

                        style:ElevatedButton.styleFrom(

                          backgroundColor:Colors.red,

                        ),


                        onPressed:() async {

                          Navigator.pop(context);

                          await FirebaseService.logout();

                          if (!context.mounted) return;

                          Navigator.pushAndRemoveUntil(

                            context,

                            MaterialPageRoute(

                              builder:(context)=>

                                  const LoginScreen(),

                            ),

                            (route)=>false,

                          );

                        },


                        child:const Text(

                          "Logout",

                          style:TextStyle(

                            color:Colors.white,

                          ),

                        ),

                      ),


                    ],

                  ),

                );

              },

              color:Colors.red,

            ),



            const SizedBox(height:40),


          ],

        ),

      ),

    );

  }





  Widget profileTile(

      IconData icon,

      String title,

      String value,

      ){

    return ListTile(

      leading:Icon(

        icon,

        color:const Color(0xFF2E7D32),

      ),


      title:Text(title),


      subtitle:Text(value),

    );

  }






  Widget settingsTile(

        IconData icon,

        String title,

        VoidCallback onTap,

        {

          Color color = Colors.black,

          Widget? trailing,

        }

        ){

    return Card(

      margin:const EdgeInsets.symmetric(

        horizontal:20,

        vertical:6,

      ),



      shape:RoundedRectangleBorder(

        borderRadius:BorderRadius.circular(15),

      ),



      child:ListTile(


        leading:Icon(

          icon,

          color:

          color == Colors.red

              ? Colors.red

              : const Color(0xFF2E7D32),

        ),



        title:Text(

          title,

          style:TextStyle(

            color:color,

          ),

        ),



        trailing: trailing ?? const Icon(

          Icons.arrow_forward_ios,

          size:16,

        ),



        onTap:onTap,


      ),

    );

  }


}