import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/context/user.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  // Toggle for enabling/disabling notifications (still local for now)
  bool _isNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Access your user context
    final userContext = Provider.of<UserContext>(context);
    // Grab the colorScheme & textTheme from the current theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Make the body extend behind the AppBar for a “floating” effect
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Manage Account'),
        // Transparent so we can see the gradient behind it
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            // Example radial gradient using colorScheme
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.8),
              radius: 1.2,
              colors: [
                colorScheme.primary.withOpacity(0.9),
                colorScheme.secondary.withOpacity(0.9),
              ],
              stops: const [0.3, 1],
            ),
          ),
        ),
      ),
      body: Container(
        // Another gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface.withOpacity(0.8),
              colorScheme.surface.withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Use a SafeArea so content isn't behind the AppBar
        child: SafeArea(
          child: Stack(
            children: [
              // A subtle frosted glass layer behind all content
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Username
                  _buildPremiumTile(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    title: 'Username',
                    subtitle: userContext.userName ?? 'Guest',
                    icon: Icons.person,
                    onTap: _editUsername,
                  ),
                  // Email
                  _buildPremiumTile(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    title: 'Email',
                    subtitle: userContext.userEmail ?? 'No email set',
                    icon: Icons.email,
                    onTap: _editEmail,
                  ),
                  const SizedBox(height: 16),

                  // Notifications toggle
                  _buildSwitchTile(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    title: 'Enable Notifications',
                    value: _isNotificationsEnabled,
                    icon: Icons.notifications,
                    onChanged: (bool value) {
                      setState(() => _isNotificationsEnabled = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Change password
                  _buildPremiumTile(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    icon: Icons.lock_open,
                    onTap: _changePassword,
                  ),
                  const SizedBox(height: 16),

                  // Delete Account
                  _buildPremiumTile(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove account',
                    icon: Icons.delete_forever,
                    // Use an error-style color scheme
                    tileColor: colorScheme.error.withOpacity(0.1),
                    iconColor: colorScheme.error,
                    titleStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Single method to enforce login. If the user isn’t logged in, navigate to /login
  //------------------------------------------------------------------------------
  void _requireLogin(VoidCallback callback) {
    final userContext = Provider.of<UserContext>(context, listen: false);
    if (!(userContext.isLoggedIn)) {
      // Or whatever property you use to detect login
      Navigator.of(context).pushNamed('/login');
    } else {
      callback();
    }
  }

  //------------------------------------------------------------------------------
  // Premium-style tile with frosted background and slight elevation
  //------------------------------------------------------------------------------
  Widget _buildPremiumTile({
    required BuildContext context,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? tileColor,
    Color? iconColor,
    TextStyle? titleStyle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Subtle background color (possibly frosted)
        color: tileColor ?? colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // A subtle border that’s visible in both light and dark
          color: colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: colorScheme.primary.withOpacity(0.1),
            child: ListTile(
              leading: Icon(icon, color: iconColor ?? colorScheme.primary),
              title: Text(
                title,
                style: titleStyle ??
                    textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------
  // A premium switch tile with a consistent style
  //------------------------------------------------------------------------------
  Widget _buildSwitchTile({
    required BuildContext context,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SwitchListTile(
          secondary: Icon(icon, color: colorScheme.primary),
          title: Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  //------------------------------------------------------------------------------
  // Edit username dialog, storing the result in UserContext
  //------------------------------------------------------------------------------
  void _editUsername() {
    _requireLogin(() {
      final userContext = Provider.of<UserContext>(context, listen: false);
      final textController = TextEditingController(
        text: userContext.userName ?? '',
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Username'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Update the UserContext
                  userContext.userName = textController.text;
                  userContext.notifyListeners();
                  Navigator.of(context).pop();
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      );
    });
  }

  //------------------------------------------------------------------------------
  // Edit email dialog, storing the result in UserContext
  //------------------------------------------------------------------------------
  void _editEmail() {
    _requireLogin(() {
      final userContext = Provider.of<UserContext>(context, listen: false);
      final textController = TextEditingController(
        text: userContext.userEmail ?? '',
      );

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Email'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  userContext.userEmail = textController.text;
                  userContext.notifyListeners();
                  Navigator.of(context).pop();
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      );
    });
  }

  //------------------------------------------------------------------------------
  // Change password logic. Just a sample - adjust for your real backend
  //------------------------------------------------------------------------------
  void _changePassword() {
    _requireLogin(() {
      final currentPasswordController = TextEditingController();
      final newPasswordController = TextEditingController();
      final confirmPasswordController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Current Password'),
                  ),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'New Password'),
                  ),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirm New Password'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  // Validate and update the password as needed
                  Navigator.of(context).pop();
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      );
    });
  }

  //------------------------------------------------------------------------------
  // Delete account logic
  //------------------------------------------------------------------------------
  void _deleteAccount() {
    _requireLogin(() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action is irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final userContext =
                    Provider.of<UserContext>(context, listen: false);
                // You could do a real "delete" API call here. For now, just log out:
                userContext.logout();
                Navigator.of(context).pop();
              },
              child: const Text('DELETE'),
            ),
          ],
        ),
      );
    });
  }
}
