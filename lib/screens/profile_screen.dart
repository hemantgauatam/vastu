import 'package:flutter/material.dart';
import '../services/account_storage.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final AccountStorage account;
  final VoidCallback onCheckForUpdates;
  final bool checkingUpdates;

  const ProfileScreen({
    super.key,
    required this.account,
    required this.onCheckForUpdates,
    required this.checkingUpdates,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _place = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _gender = 'Male';
  String _userType = 'Customer';
  bool _loginMode = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.account.profile;
    if (profile != null) {
      _name.text = profile.name;
      _email.text = profile.email;
      _phone.text = profile.phone;
      _place.text = profile.place;
      _username.text = profile.username;
      if (profile.gender.isNotEmpty) _gender = profile.gender;
      if (profile.userType.isNotEmpty) _userType = profile.userType;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _place.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.account,
      builder: (context, _) {
        final profile = widget.account.profile;
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth < 380 ? 10.0 : 16.0;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                padding,
                8,
                padding,
                24 + keyboardInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'USER ACCOUNT',
                        style: AppTheme.uiLabel(
                          size: 10,
                          color: AppTheme.gold.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile',
                        style: AppTheme.divineTitle(size: 30),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildUpdateCard(),
                      const SizedBox(height: 16),
                      if (profile == null)
                        _buildAccountForm()
                      else ...[
                        _buildProfile(profile),
                        const SizedBox(height: 16),
                        _buildPurchases(),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _saving ? null : _deleteAccount,
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          label: const Text('Delete account',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently delete account?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Your account, reviews, order history and saved cart will be removed. This cannot be undone. Enter your password to confirm.'),
          const SizedBox(height: 12),
          TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete account')),
        ],
      ),
    );
    final value = password.text;
    password.dispose();
    if (confirmed != true || !mounted) return;
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter your password to delete your account.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.account.deleteAccount(value);
      for (final field in [
        _name,
        _email,
        _phone,
        _place,
        _username,
        _password,
        _confirmPassword
      ]) {
        field.clear();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has been deleted.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account could not be deleted: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildUpdateCard() {
    return InkWell(
      onTap: widget.checkingUpdates ? null : widget.onCheckForUpdates,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration(radius: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.goldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: widget.checkingUpdates
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.gold,
                      ),
                    )
                  : const Icon(
                      Icons.system_update_alt,
                      size: 20,
                      color: AppTheme.gold,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Update',
                    style: AppTheme.uiText(size: 14, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.checkingUpdates
                        ? 'Checking latest version...'
                        : 'Check latest Kuber Vastu app version.',
                    style: AppTheme.uiText(size: 11, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppTheme.gold.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountForm() {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: AppTheme.cardDecoration(radius: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _loginMode ? 'Login' : 'Create account',
                  style: AppTheme.divineTitle(size: 23),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() => _loginMode = !_loginMode),
                  child: Text(_loginMode ? 'Register' : 'Login'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _loginMode
                  ? 'Login with the username and password created during registration.'
                  : 'Create your user record before purchasing remedies.',
              style: AppTheme.uiText(
                size: 12,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 16),
            if (!_loginMode) ...[
              _field(_name, 'Name', Icons.person_outline),
              const SizedBox(height: 10),
              _dropdownField(
                label: 'Male / Female',
                icon: Icons.wc_outlined,
                value: _gender,
                items: const ['Male', 'Female'],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 10),
            ],
            _field(_username, 'Username', Icons.account_circle_outlined),
            const SizedBox(height: 10),
            if (!_loginMode) ...[
              _field(
                _phone,
                'Mobile No',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _field(_email, 'Mail ID', Icons.email_outlined, email: true),
              const SizedBox(height: 10),
              _field(_place, 'Place', Icons.place_outlined),
              const SizedBox(height: 10),
              _dropdownField(
                label: 'Who are you?',
                icon: Icons.badge_outlined,
                value: _userType,
                items: const ['Customer', 'Vastu Expert', 'Astrologer'],
                onChanged: (value) => setState(() => _userType = value),
              ),
              const SizedBox(height: 10),
            ],
            _field(_password, 'Password', Icons.lock_outline, password: true),
            if (!_loginMode) ...[
              const SizedBox(height: 10),
              _field(
                _confirmPassword,
                'Confirm Password',
                Icons.lock_reset_outlined,
                password: true,
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _saving ? null : _submitAccount,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: AppTheme.goldButtonDecoration(radius: 10),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.cream,
                        ),
                      )
                    : Text(
                        _loginMode ? 'Login' : 'Create Account',
                        style: AppTheme.uiText(
                          size: 14,
                          weight: FontWeight.w700,
                          color: AppTheme.cream,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _loginMode
                    ? 'Use your username and password to login.'
                    : 'Password must be at least 6 characters.',
                style: AppTheme.uiText(
                  size: 11,
                  color: AppTheme.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration(radius: 10),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.gold, Color(0xFFB8933F)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.28),
                  blurRadius: 22,
                ),
              ],
            ),
            child: Text(
              profile.initials,
              style: AppTheme.uiText(
                size: 22,
                weight: FontWeight.w800,
                color: AppTheme.cream,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.divineTitle(size: 25),
          ),
          const SizedBox(height: 4),
          if (profile.username.isNotEmpty) ...[
            Text(
              '@${profile.username}',
              style: AppTheme.uiText(
                size: 12,
                color: AppTheme.goldBright,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            profile.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.uiText(
              size: 12,
              color: AppTheme.muted,
            ),
          ),
          if (profile.phone.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Mobile: ${profile.phone}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTheme.uiText(
                size: 12,
                color: AppTheme.muted,
              ),
            ),
          ],
          if (profile.gender.isNotEmpty ||
              profile.place.isNotEmpty ||
              profile.userType.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.gender.isNotEmpty)
                  _profileChip(Icons.wc_outlined, profile.gender),
                if (profile.place.isNotEmpty)
                  _profileChip(Icons.place_outlined, profile.place),
                if (profile.userType.isNotEmpty)
                  _profileChip(Icons.badge_outlined, profile.userType),
              ],
            ),
          ],
          const SizedBox(height: 16),
          InkWell(
            onTap: _saving ? null : () => widget.account.signOut(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: AppTheme.insetPanelDecoration(radius: 10),
              child: Text(
                _saving ? 'Please wait...' : 'Logout',
                style: AppTheme.uiText(size: 13, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchases() {
    final orders = widget.account.orders;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(radius: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchase History', style: AppTheme.divineTitle(size: 20)),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            Text(
              'Completed remedy purchases will appear here.',
              style: AppTheme.uiText(
                size: 12,
                color: AppTheme.muted,
              ),
            )
          else
            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 320;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: AppTheme.goldBright,
                        ),
                        SizedBox(
                          width: compact
                              ? (constraints.maxWidth - 28)
                                  .clamp(120.0, constraints.maxWidth)
                                  .toDouble()
                              : (constraints.maxWidth - 100)
                                  .clamp(140.0, constraints.maxWidth)
                                  .toDouble(),
                          child: Text(
                            order.quantity > 1
                                ? '${order.remedyName} x${order.quantity}'
                                : order.remedyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.uiText(
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          order.validityEndsAt == null
                              ? 'Rs ${order.price}'
                              : 'Rs ${order.price}\nValid until ${order.validityEndsAt!.day}/${order.validityEndsAt!.month}/${order.validityEndsAt!.year}',
                          textAlign: TextAlign.right,
                          style: AppTheme.uiText(
                            size: 12,
                            color: AppTheme.goldBright,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool email = false,
    bool password = false,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: password,
      keyboardType: keyboardType ??
          (email ? TextInputType.emailAddress : TextInputType.text),
      style: AppTheme.uiText(size: 13),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return '$label is required';
        if (email && !text.contains('@')) return 'Enter a valid email';
        if (label == 'Username' && text.contains(' ')) {
          return 'Username cannot contain spaces';
        }
        if (label == 'Username' && text.length < 3) {
          return 'Username must be at least 3 characters';
        }
        if (label == 'Mobile No' &&
            !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(text.replaceAll(' ', ''))) {
          return 'Enter a valid mobile number';
        }
        if (password && text.length < 6) return 'Minimum 6 characters';
        if (label == 'Confirm Password' && text != _password.text) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: AppTheme.inputDecoration(label: label, icon: icon),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppTheme.bgPanel,
      style: AppTheme.uiText(size: 13),
      validator: (selected) {
        if ((selected ?? '').trim().isEmpty) return '$label is required';
        return null;
      },
      decoration: AppTheme.inputDecoration(label: label, icon: icon),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  Widget _profileChip(IconData icon, String label) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 64,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: AppTheme.insetPanelDecoration(radius: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.goldBright),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 110,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.uiText(
                size: 11,
                color: AppTheme.body,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_loginMode) {
        await widget.account.login(
          username: _username.text,
          password: _password.text,
        );
      } else {
        await widget.account.register(
          name: _name.text,
          gender: _gender,
          email: _email.text,
          phone: _phone.text,
          place: _place.text,
          userType: _userType,
          username: _username.text,
          password: _password.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Account failed: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
