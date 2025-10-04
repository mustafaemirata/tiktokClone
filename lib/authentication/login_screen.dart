import 'package:cloneshorts/authentication/register_screen.dart';
import 'package:cloneshorts/authentication/authentication_controller.dart';
import 'package:cloneshorts/global.dart';
import 'package:cloneshorts/widgets/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final authenticationController = AuthenticationController.instanceAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 200),
              Image.asset("images/youtube.png", width: 100),
              SizedBox(height: 30),
              Text(
                "Hoş geldiniz!",
                style: GoogleFonts.acme(
                  fontSize: 34,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),

              //email
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
              //sifre
              SizedBox(height: 10),
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
              SizedBox(height: 10),
              Obx(
                () => showProgress.value == false
                    ? Column(
                        children: [
                          //login buton
                          Container(
                            width: MediaQuery.of(context).size.width - 30,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (emailController.text.isNotEmpty &&
                                    passwordController.text.isNotEmpty) {
                                  showProgress.value = true;
                                  authenticationController.loginUser(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  );
                                } else {
                                  Get.snackbar(
                                    "Hata",
                                    "Lütfen tüm alanları doldurun!",
                                  );
                                }
                              },
                              child: const Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          //hesap yok mu, üye ol
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Hesabınız yok mu?",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  //sign up'a gönder
                                  Get.to(() => RegisterScreen());
                                },
                                child: const Text(
                                  "Kayıt Ol!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Debug butonu (sadece debug modda görünür)
                          if (kDebugMode)
                            InkWell(
                              onTap: () {
                                authenticationController.debugListAllUsers();
                              },
                              child: const Text(
                                "Debug: Kullanıcıları Listele",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SimpleCircularProgressBar(
                        progressColors: [
                          Colors.green,
                          Colors.blueAccent,
                          Colors.red,
                          Colors.amber,
                          Colors.purpleAccent,
                        ],
                        animationDuration: 3,
                        backColor: Colors.white30,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
