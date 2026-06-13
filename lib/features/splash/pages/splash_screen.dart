import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../home_karyawan/presentation/pages/home_karyawan_page.dart';
import 'forgot_password_page.dart';

class SplashScreen extends StatefulWidget {
  final bool showLoginImmediately;
  const SplashScreen({super.key, this.showLoginImmediately = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.showLoginImmediately ? 2 : 0;
    _pageController = PageController(initialPage: _currentPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          final userData = userDoc.data();
          final role = userData?['role'] as String?;
          final status = userData?['status'] as String?;

          if (role == 'karyawan') {
            if (status == 'suspend') {
              await FirebaseAuth.instance.signOut();
              
              // Find owner phone number
              String? ownerPhone;
              final restoId = userData?['resto_id'] as String?;
              if (restoId != null && restoId.isNotEmpty) {
                final restoDoc = await FirebaseFirestore.instance.collection('restaurants').doc(restoId).get();
                if (restoDoc.exists) {
                  final ownerId = restoDoc.data()?['owner_id'] as String?;
                  if (ownerId != null) {
                    final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
                    if (ownerDoc.exists) {
                      ownerPhone = ownerDoc.data()?['url_whatsapp'] as String?;
                    }
                  }
                  if (ownerPhone == null || ownerPhone.isEmpty) {
                    ownerPhone = restoDoc.data()?['url_whatsapp'] as String?;
                  }
                }
              }

              if (mounted) {
                _showSuspendedDialog(context, ownerPhone);
                
                // Proceed with splash flow
                if (widget.showLoginImmediately) {
                  _showLoginSheet();
                } else {
                  _playTeaserAnimation();
                }
              }
              return;
            } else {
              // Active employee, redirect to employee home screen
              if (mounted) {
                final restoId = userData?['resto_id'] as String? ?? '';
                final namaKaryawan = userData?['nama'] as String? ?? 'Karyawan';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KaryawanHomePage(
                      restoId: restoId,
                      namaKaryawan: namaKaryawan,
                    ),
                  ),
                );
              }
              return;
            }
          } else {
            // Normal user/owner
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
            return;
          }
        }
      } catch (e) {
        // Fallback to normal flow if firestore check fails
      }
    }

    if (mounted) {
      if (widget.showLoginImmediately) {
        _showLoginSheet();
      } else {
        _playTeaserAnimation();
      }
    }
  }

  void _playTeaserAnimation() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted || _currentPage != 0) return;

    try {
      final double width = MediaQuery.of(context).size.width;
      final double peekOffset = width * 0.18;

      await _pageController.animateTo(
        peekOffset,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || _currentPage != 0) return;

      await _pageController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutBack,
      );
    } catch (e) {
      // Guard in case page controller is not attached or disposed
    }
  }

  void _showLoginSheet() {
    final sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650), // Smooth and premium slide duration
      reverseDuration: const Duration(milliseconds: 450),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionAnimationController: sheetController,
      builder: (context) => const _LoginRegisterSheet(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              SplashPage1(isActive: _currentPage == 0),
              SplashPage2(isActive: _currentPage == 1),
              SplashPage3(
                isActive: _currentPage == 2,
                onMulaiSekarang: _showLoginSheet,
              ),
            ],
          ),

          // Blinking Chevron Right Indicator (Center-Right)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AnimatedOpacity(
                opacity: _currentPage < 2 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const IgnorePointer(
                  child: BlinkingChevronIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login / Register Bottom Sheet ──────────────────────────────────────────

class _LoginRegisterSheet extends StatefulWidget {
  const _LoginRegisterSheet();

  @override
  State<_LoginRegisterSheet> createState() => _LoginRegisterSheetState();
}

class _LoginRegisterSheetState extends State<_LoginRegisterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasKeyboard = bottomInset > 0;
    
    // Fixed height when keyboard is closed to prevent the background glass container from resizing/jumping
    final sheetHeight = hasKeyboard ? screenHeight * 0.82 : 680.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: sheetHeight,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.88,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35), // Liquid glass look (lowered opacity)
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Tab Selector (Login / Daftar)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, 'Login'),
                        _buildTab(1, 'Daftar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tab content with premium slide animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOutQuart,
                    switchOutCurve: Curves.easeInOutQuart,
                    transitionBuilder: (child, animation) {
                      final isLogin = child.key == const ValueKey('login');
                      final isIncoming = (child.key == const ValueKey('login') && _tabController.index == 0) ||
                          (child.key == const ValueKey('register') && _tabController.index == 1);
                      
                      // Slide direction: Login comes from left (-1.2), Register comes from right (1.2)
                      final slideOffset = isLogin ? const Offset(-1.2, 0.0) : const Offset(1.2, 0.0);
                      
                      return ClipRect(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: isIncoming ? slideOffset : -slideOffset,
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _tabController.index == 0
                        ? const _LoginForm(key: ValueKey('login'))
                        : const _RegisterForm(key: ValueKey('register')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Login Form ─────────────────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi email dan password dulu ya!')),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r"^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email salah yakk!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          final role = userData?['role'] as String?;
          final status = userData?['status'] as String?;

          if (role == 'karyawan') {
            if (status == 'suspend') {
              await FirebaseAuth.instance.signOut();
              
              // Find owner phone number
              String? ownerPhone;
              final restoId = userData?['resto_id'] as String?;
              if (restoId != null && restoId.isNotEmpty) {
                final restoDoc = await FirebaseFirestore.instance.collection('restaurants').doc(restoId).get();
                if (restoDoc.exists) {
                  final ownerId = restoDoc.data()?['owner_id'] as String?;
                  if (ownerId != null) {
                    final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
                    if (ownerDoc.exists) {
                      ownerPhone = ownerDoc.data()?['url_whatsapp'] as String?;
                    }
                  }
                  if (ownerPhone == null || ownerPhone.isEmpty) {
                    ownerPhone = restoDoc.data()?['url_whatsapp'] as String?;
                  }
                }
              }

              if (mounted) {
                setState(() => _isLoading = false);
                _showSuspendedDialog(context, ownerPhone);
              }
              return;
            } else {
              // Active employee, redirect to employee home screen
              if (mounted) {
                final restoId = userData?['resto_id'] as String? ?? '';
                final namaKaryawan = userData?['nama'] as String? ?? 'Karyawan';
                Navigator.of(context).pop(); // Close bottom sheet
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KaryawanHomePage(
                      restoId: restoId,
                      namaKaryawan: namaKaryawan,
                    ),
                  ),
                );
              }
              return;
            }
          }
        }
      }

      // Default redirect for customers/owners
      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                  position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal login, periksa email dan password.';
      if (e.code == 'user-not-found') msg = 'Email tidak terdaftar.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential')
        msg = 'Email atau password salah.';
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 530,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WELCOME\nBACK',
            style: GoogleFonts.outfit(
              fontSize: 46,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          _label('Email'),
          _textField('Masukkin email kamu yakk',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('Password'),
          _textField(
            'Masukkin password unik kamu',
            controller: _passwordController,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordPage(),
                  ),
                );
              },
              child: Text(
                'Lupa Password?',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Login',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Image.asset('assets/images/Icon/google_logo.png', width: 22),
              label: Text(
                'Login pake Google',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Register Form ───────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({super.key});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telpController = TextEditingController();
  DateTime? _tanggalLahir;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telpController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _tanggalLahir == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Tolong isi semua data utama termasuk tanggal lahir ya!')));
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r"^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      setState(() => _emailError = 'Format email salah yakk!');
      return;
    }

    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _passwordError = 'Password minimal harus 8 karakter yakk!');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() =>
          _passwordError = 'Password harus mengandung minimal 1 huruf kapital yakk!');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      setState(() =>
          _passwordError = 'Password harus mengandung minimal 1 angka yakk!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'id': credential.user!.uid,
          'nama': _namaController.text.trim(),
          'email': email,
          'password': password,
          'role': 'customer',
          'url_whatsapp': _telpController.text.trim(),
          'tanggal_lahir': Timestamp.fromDate(_tanggalLahir!),
          'status': 'aktif',
          'poin_reward': 0,
          'created_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.of(context).pop(); // Close bottom sheet
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomePage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutQuart;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                    position: animation.drive(tween), child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        setState(() => _passwordError = 'Password terlalu lemah yakk!');
      } else if (e.code == 'email-already-in-use') {
        setState(() => _emailError = 'Email sudah terdaftar yakk!');
      } else {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Terjadi kesalahan')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTanggalLahir() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _tanggalLahir) {
      setState(() => _tanggalLahir = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 530,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _label('Nama'),
          _textField('Masukkin nama kamu yakk', controller: _namaController),
          const SizedBox(height: 16),
          _label('Email'),
          _textField('Masukkin email kamu yakk',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress),
          if (_emailError != null) _errorText(_emailError!),
          const SizedBox(height: 16),
          _label('Password'),
          _textField(
            'Masukkin password unik kamu',
            controller: _passwordController,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          if (_passwordError != null) _errorText(_passwordError!),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tanggal Lahir'),
                    _dateField(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('No telp'),
                    _textField('', controller: _telpController,
                        keyboardType: TextInputType.phone),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Gass Daftar',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Image.asset('assets/images/Icon/google_logo.png', width: 22),
              label: Text(
                'Login pake Google',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    final String text = _tanggalLahir != null
        ? '${_tanggalLahir!.day.toString().padLeft(2, '0')}-${_tanggalLahir!.month.toString().padLeft(2, '0')}-${_tanggalLahir!.year}'
        : 'Pilih tanggal';
    return GestureDetector(
      onTap: _selectTanggalLahir,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color:
                      _tanggalLahir != null ? Colors.black : Colors.grey,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_month, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _errorText(String msg) => Padding(
        padding: const EdgeInsets.only(left: 8, top: 4),
        child: Text(msg,
            style: GoogleFonts.outfit(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
}

// ─── Shared field helpers (module-level) ─────────────────────────────────────

Widget _label(String label) => Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );

Widget _textField(
  String hint, {
  bool isPassword = false,
  bool obscureText = false,
  VoidCallback? onToggleVisibility,
  TextEditingController? controller,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30)),
    child: TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    ),
  );
}

// ─── Blinking Chevron Indicator ──────────────────────────────────────────────

class BlinkingChevronIndicator extends StatefulWidget {
  const BlinkingChevronIndicator({super.key});

  @override
  State<BlinkingChevronIndicator> createState() =>
      _BlinkingChevronIndicatorState();
}

class _BlinkingChevronIndicatorState extends State<BlinkingChevronIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }
}

// ─── Splash Pages ─────────────────────────────────────────────────────────────

class SplashPage1 extends StatefulWidget {
  final bool isActive;
  const SplashPage1({super.key, required this.isActive});

  @override
  State<SplashPage1> createState() => _SplashPage1State();
}

class _SplashPage1State extends State<SplashPage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _imageOffsetAnimation;
  late Animation<Offset> _titleOffsetAnimation;
  late Animation<Offset> _subtitleOffsetAnimation;
  late Animation<double> _textOpacityAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _imageOffsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart)));

    _titleOffsetAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _controller,
                curve:
                    const Interval(0.5, 1.0, curve: Curves.easeOutQuart)));

    _subtitleOffsetAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve:
                    const Interval(0.5, 1.0, curve: Curves.easeOutQuart)));

    _textOpacityAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.7, curve: Curves.easeIn));

    if (widget.isActive) _startAnimation();
  }

  void _startAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(SplashPage1 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SlideTransition(
        position: _imageOffsetAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash_screen/splash pic 1.png',
                fit: BoxFit.cover, alignment: Alignment.center),
            Container(color: Colors.black.withOpacity(0.5)),
            Positioned(
              left: 24,
              right: 24,
              bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: SlideTransition(
                      position: _titleOffsetAnimation,
                      child: Text("Gas\nCari\nMakan",
                          style: GoogleFonts.outfit(
                              fontSize: 90,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: 1.0)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: SlideTransition(
                      position: _subtitleOffsetAnimation,
                      child: Text(
                          "Lapar tapi malas antre lama? Sekarang Anda bisa cek antrean dine-in sebelum datang. Datang di waktu yang tepat, makan tanpa buang waktu.",
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashPage2 extends StatefulWidget {
  final bool isActive;
  const SplashPage2({super.key, required this.isActive});

  @override
  State<SplashPage2> createState() => _SplashPage2State();
}

class _SplashPage2State extends State<SplashPage2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _titleOffsetAnimation;
  late Animation<Offset> _subtitleOffsetAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _subtitleOpacityAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    _titleOffsetAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart)));

    _subtitleOffsetAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve:
                    const Interval(0.4, 1.0, curve: Curves.easeOutQuart)));

    _titleOpacityAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn));

    _subtitleOpacityAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn));

    if (widget.isActive) _startAnimation();
  }

  void _startAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(SplashPage2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/splash_screen/splash pic 2.png',
            fit: BoxFit.cover, alignment: Alignment.center),
        Container(color: Colors.black.withOpacity(0.5)),
        Positioned(
          left: 24,
          right: 24,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _titleOpacityAnimation,
                child: SlideTransition(
                  position: _titleOffsetAnimation,
                  child: Text("Mau\nMakan\nNunggu\nLama?",
                      style: GoogleFonts.outfit(
                          fontSize: 90,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _subtitleOpacityAnimation,
                child: SlideTransition(
                  position: _subtitleOffsetAnimation,
                  child: Text(
                      "Tenang sekarang udah ada CariMakan, dengan kamu pake app ini kamu gaperlu khawatir orderan kamu bakalan lama",
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.white, height: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SplashPage3 extends StatefulWidget {
  final bool isActive;
  final VoidCallback onMulaiSekarang;
  const SplashPage3(
      {super.key, required this.isActive, required this.onMulaiSekarang});

  @override
  State<SplashPage3> createState() => _SplashPage3State();
}

class _SplashPage3State extends State<SplashPage3>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _titleOffsetAnimation;
  late Animation<Offset> _subtitleOffsetAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _subtitleOpacityAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    _titleOffsetAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart)));

    _subtitleOffsetAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _controller,
                curve:
                    const Interval(0.4, 1.0, curve: Curves.easeOutQuart)));

    _titleOpacityAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn));

    _subtitleOpacityAnimation = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn));

    if (widget.isActive) _startAnimation();
  }

  void _startAnimation() {
    if (_hasAnimated) return;
    _hasAnimated = true;
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(SplashPage3 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/splash_screen/splash pic 3.png',
            fit: BoxFit.cover, alignment: Alignment.center),
        Container(color: Colors.black.withOpacity(0.5)),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _titleOpacityAnimation,
                child: SlideTransition(
                  position: _titleOffsetAnimation,
                  child: Text("Pesan\nDari\nMana\nAja!",
                      style: GoogleFonts.outfit(
                          fontSize: 90,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: 1.0)),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _subtitleOpacityAnimation,
                child: SlideTransition(
                  position: _subtitleOffsetAnimation,
                  child: Text(
                      "Mau makan di tempat atau bawa pulang? Tinggal pilih restoran, cek antrean, dan pesan langsung dari aplikasi. Semudah itu!",
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.white, height: 1.5)),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _subtitleOpacityAnimation,
                child: SlideTransition(
                  position: _subtitleOffsetAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      // ← Now shows the bottom sheet instead of navigating
                      onPressed: widget.onMulaiSekarang,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Text("Mulai Sekarang",
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showSuspendedDialog(BuildContext context, String? ownerPhone) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD33400), size: 28),
          const SizedBox(width: 12),
          Text(
            'Akun Ditangguhkan',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C1C),
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akun karyawan Anda telah ditangguhkan (suspended) oleh pemilik restoran.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF4B5563),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Silakan hubungi pemilik restoran Anda untuk mengaktifkan kembali akun.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF4B5563),
              fontSize: 15,
            ),
          ),
          if (ownerPhone != null && ownerPhone.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD33400).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFFD33400), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      ownerPhone,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD33400),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
          ),
          child: Text(
            'Tutup',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
