import 'package:flutter/material.dart';
import 'package:connect/auth/auth_service.dart';
import 'package:connect/components/my_button.dart';
import 'package:connect/components/my_textfield.dart';

class LoginPage extends StatelessWidget {
  //email and pw controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  // tap to go to register page
  final void Function()? onTap;

  LoginPage({
    super.key,
    required this.onTap,
  });

  void login(BuildContext context) async {
    // auth service
    final authService = AuthService();
    //try login
    try {
      await authService.signInWithEmailPassword(_emailController.text, _pwController.text, );
    }
    // catch errors
    catch (e) {
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text(e.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo
            Image.asset(
              "assets/images/connect-icon.png",
              width: 60,
              height: 60,
              color: const Color(0xFF00A8FF),
            ),// Corrected
            const SizedBox(
              height: 50,
            ),
            // welcome
            Text(
              "Welcome, let's connect!",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 25,
            ),
            //email
            MyTextField(
              hintText: "Email",
              obscureText: false,
              controller: _emailController,
            ),

            const SizedBox(
              height: 25,
            ),
            //password
            MyTextField(
              hintText: "Password",
              obscureText: true,
              controller: _pwController,
            ),

            const SizedBox(
              height: 25,
            ),
            //login button
            MyButton(
              text: "Login",
              onTap: () => login(context),
            ),

            const SizedBox(
              height: 25,
            ),
            //register now

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Not a member? ",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    "Register now",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
