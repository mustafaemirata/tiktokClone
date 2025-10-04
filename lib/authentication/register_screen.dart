import 'package:cloneshorts/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'dart:io';

import 'authentication_controller.dart';
import '../widgets/input.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final authenticationController = AuthenticationController.instanceAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 150),

              // Başlık
              Text(
                "Hesap Oluştur!",
                style: GoogleFonts.acme(
                  fontSize: 34,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Profil resmi
              Obx(() {
                File? imageFile = authenticationController.profileImage;
                return GestureDetector(
                  onTap: () => authenticationController.chooseImageGallery(),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile)
                        : AssetImage("images/9.png") as ImageProvider,
                    backgroundColor: Colors.black,
                  ),
                );
              }),
              SizedBox(height: 20),

              // İsim
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: InputText(
                  textEditingController: nameController,
                  labelString: "İsim",
                  icon: Icons.person_2_outlined,
                  isObscure: false,
                ),
              ),
              SizedBox(height: 10),

              // Email
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: InputText(
                  textEditingController: emailController,
                  labelString: "Email",
                  icon: Icons.email_outlined,
                  isObscure: false,
                ),
              ),
              SizedBox(height: 10),

              // Şifre
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: InputText(
                  textEditingController: passwordController,
                  labelString: "Şifre",
                  icon: Icons.lock,
                  isObscure: true,
                ),
              ),
              SizedBox(height: 20),

              // Kayıt / Progress
              Obx(() => showProgress.value
                  ? const SimpleCircularProgressBar(
                      progressColors: [
                        Colors.green,
                        Colors.blueAccent,
                        Colors.red,
                        Colors.amber,
                        Colors.purpleAccent,
                      ],
                      animationDuration: 3,
                      backColor: Colors.white30,
                    )
                  : Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width - 30,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (authenticationController.profileImage !=
                                      null &&
                                  nameController.text.isNotEmpty &&
                                  emailController.text.isNotEmpty &&
                                  passwordController.text.isNotEmpty) {
                                showProgress.value = true;
                                authenticationController.createAccount(
                                  authenticationController.profileImage!,
                                  nameController.text.trim(),
                                  emailController.text.trim(),
                                  passwordController.text.trim(),
                                );
                              } else {
                                Get.snackbar("Hata", "Lütfen tüm alanları doldurun ve profil resmi seçin!");
                              }
                            },
                            child: const Center(
                              child: Text(
                                "Kayıt Ol",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Login sayfasına geçiş
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Hesabın var mı?",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                Get.to(() => const LoginPage());
                              },
                              child: const Text(
                                "Giriş Yap!",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
