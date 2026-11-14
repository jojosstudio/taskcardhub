import 'dart:convert';

import 'package:clerk_native/clerk_native.dart';
import 'package:clerk_native_ui/clerk_native_ui.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _publishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
  defaultValue: 'pk_live_Y2xlcmsuam9qb3NzdHVkaW8uZGUk',
);
const _apiBase = 'https://hub.jojosstudio.de';
const _currentVersion = '1.0.0';
const _versionManifestUrl = 'https://raw.githubusercontent.com/jojosstudio/taskcardhub/main/version.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? clerkError;
  try {
    await Clerk.initialize(publishableKey: _publishableKey);
  } catch (error) {
    clerkError = error;
  }
  runApp(TaskcardHubApp(clerkError: clerkError));
}

class TaskcardHubApp extends StatelessWidget {
  const TaskcardHubApp({super.key, this.clerkError});

  final Object? clerkError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskcard Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF121A2A),
          indicatorColor: Color(0xFF1D4ED8),
        ),
      ),
      home: clerkError == null
          ? const ClerkAuthStateGate()
          : ClerkSetupError(error: clerkError!),
    );
  }
}

class ClerkAuthStateGate extends StatelessWidget {
  const ClerkAuthStateGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ClerkAuthStateBuilder(
      signedIn: (context, user) => TaskcardShell(
        isSignedIn: true,
        displayName: user.firstName ?? user.username ?? 'Nutzer',
      ),
      signedOut: (context) => const TaskcardShell(isSignedIn: false),
      loading: (context) => const LoadingScreen(),
      error: (context, error) => ClerkSetupError(error: error),
    );
  }
}

class ClerkSetupError extends StatelessWidget {
  const ClerkSetupError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 52, color: Color(0xFF60A5FA)),
              const SizedBox(height: 18),
              const Text('Clerk konnte nicht geladen werden', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: 0.92 + (_controller.value * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(angle: _controller.value * 0.18, child: child),
                const SizedBox(height: 18),
                const Text('Taskcard Hub wird geladen ...', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          child: const BrandMark(size: 66),
        ),
      ),
    );
  }
}

class Taskcard {
  const Taskcard({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.course,
    required this.topic,
    required this.url,
    required this.confirmed,
    required this.createdByName,
    required this.teachers,
    this.description,
  });

  factory Taskcard.fromJson(Map<String, dynamic> json) {
    return Taskcard(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Ohne Titel',
      subject: json['subject'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      course: json['course'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      url: json['url'] as String? ?? '',
      confirmed: json['confirmed'] as bool? ?? false,
      createdByName: json['createdByName'] as String? ?? 'Unbekannter Nutzer',
      description: json['description'] as String?,
      teachers: (json['teachers'] as List<dynamic>? ?? [])
          .map((teacher) => (teacher as Map<String, dynamic>)['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
    );
  }

  final String id;
  final String title;
  final String subject;
  final String grade;
  final String course;
  final String topic;
  final String url;
  final bool confirmed;
  final String createdByName;
  final List<String> teachers;
  final String? description;
}

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.build,
    required this.title,
    required this.notes,
    required this.downloadUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      version: json['version'] as String? ?? _currentVersion,
      build: json['build'] as int? ?? 0,
      title: json['title'] as String? ?? 'Taskcard Hub Update',
      notes: (json['notes'] as List<dynamic>? ?? []).whereType<String>().toList(),
      downloadUrl: json['downloadUrl'] as String? ?? 'https://github.com/jojosstudio/taskcardhub/releases/latest',
    );
  }

  final String version;
  final int build;
  final String title;
  final List<String> notes;
  final String downloadUrl;

  bool get isNewer => _compareVersions(version, _currentVersion) > 0;
}

Future<AppUpdateInfo> checkForAppUpdate() async {
  final response = await http.get(Uri.parse(_versionManifestUrl)).timeout(const Duration(seconds: 8));
  if (response.statusCode != 200) {
    throw Exception('Versionsprüfung fehlgeschlagen (${response.statusCode}).');
  }
  return AppUpdateInfo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
}

int _compareVersions(String first, String second) {
  final left = first.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  final right = second.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  for (var index = 0; index < 3; index++) {
    final leftPart = index < left.length ? left[index] : 0;
    final rightPart = index < right.length ? right[index] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }
  return 0;
}

class TaskcardApi {
  static Future<List<Taskcard>> loadCards() async {
    final response = await http.get(Uri.parse('$_apiBase/api/taskcards'));
    if (response.statusCode != 200) {
      throw Exception('Taskcards konnten nicht geladen werden (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['cards'] as List<dynamic>)
        .map((card) => Taskcard.fromJson(card as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createCard(Map<String, String> form) async {
    final token = await Clerk.instance.getToken();
    if (token == null) throw Exception('Bitte melde dich zuerst an.');
    final response = await http.post(
      Uri.parse('$_apiBase/api/taskcards'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(form),
    );
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] as String? ?? 'Taskcard konnte nicht gespeichert werden.');
    }
  }
}

class TaskcardShell extends StatefulWidget {
  const TaskcardShell({super.key, required this.isSignedIn, this.displayName});

  final bool isSignedIn;
  final String? displayName;

  @override
  State<TaskcardShell> createState() => _TaskcardShellState();
}

class _TaskcardShellState extends State<TaskcardShell> {
  int _tab = 0;
  late final PageController _pageController;
  String _query = '';
  String _subject = 'Alle Fächer';
  String _status = 'Alle Status';
  late Future<List<Taskcard>> _cards;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cards = TaskcardApi.loadCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _reload() {
    final cards = TaskcardApi.loadCards();
    setState(() {
      _cards = cards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Taskcard Hub', 'Suchen', 'Hinzufügen', 'Profil'];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Row(
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: 10),
            Text(titles[_tab], style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF0B0F18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 92),
        child: FutureBuilder<List<Taskcard>>(
          future: _cards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const LoadingScreen();
            if (snapshot.hasError) {
              return ErrorPanel(message: '${snapshot.error}', onRetry: _reload);
            }
            final cards = snapshot.data ?? [];
            return PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _tab = index),
              children: [
                _Refreshable(onRefresh: _reload, child: TaskcardList(cards: cards, query: '', subject: 'Alle Fächer', status: 'Alle Status', onOpen: _openCard)),
                SearchPage(
                  cards: cards,
                  query: _query,
                  subject: _subject,
                  status: _status,
                  onQuery: (value) => setState(() => _query = value),
                  onSubject: (value) => setState(() => _subject = value),
                  onStatus: (value) => setState(() => _status = value),
                  onOpen: _openCard,
                  onRefresh: _reload,
                ),
                _Refreshable(
                  onRefresh: _reload,
                  child: AddCardPage(isSignedIn: widget.isSignedIn, onSaved: () {
                    _reload();
                    setState(() => _tab = 0);
                  }),
                ),
                _Refreshable(onRefresh: _reload, child: ProfilePage(isSignedIn: widget.isSignedIn, displayName: widget.displayName)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        child: FloatingDock(
          selectedIndex: _tab,
          onSelected: (index) => _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          ),
          onSwipe: (direction) {
            final next = (_tab + direction).clamp(0, 3).toInt();
            _pageController.animateToPage(
              next,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCard(Taskcard card) async {
    if (!card.confirmed) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Link nicht bestätigt'),
          content: const Text('Diese Taskcard wurde noch nicht von einem Lehrer oder Admin geprüft. Der Link kann fehlerhaft oder unsicher sein.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Trotzdem öffnen')),
          ],
        ),
      );
      if (open != true) return;
    }
    final uri = Uri.tryParse(card.url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link konnte nicht geöffnet werden.')));
    }
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .25),
        boxShadow: const [BoxShadow(color: Color(0x333B82F6), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class FloatingDock extends StatefulWidget {
  const FloatingDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSwipe,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onSwipe;

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  bool _isDragging = false;
  int? _previewIndex;

  int _indexForX(double x, double width) {
    final index = (x / (width / 4)).floor();
    return index.clamp(0, 3);
  }

  void _finishDrag() {
    final index = _previewIndex;
    setState(() {
      _isDragging = false;
      _previewIndex = null;
    });
    if (index != null) widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.home_outlined, Icons.home, 'Start'),
      (Icons.search, Icons.search, 'Suchen'),
      (Icons.add, Icons.add, 'Neu'),
      (Icons.person_outline, Icons.person, 'Profil'),
    ];
    final width = MediaQuery.sizeOf(context).width - 16;
    final activeIndex = _previewIndex ?? widget.selectedIndex;
    return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() > 200) widget.onSwipe(velocity < 0 ? 1 : -1);
          },
          onLongPressStart: (details) => setState(() {
            _isDragging = true;
            _previewIndex = _indexForX(details.localPosition.dx, width);
          }),
          onLongPressMoveUpdate: (details) => setState(() {
            _previewIndex = _indexForX(details.localPosition.dx, width);
          }),
          onLongPressEnd: (_) => _finishDrag(),
          onLongPressCancel: _finishDrag,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: _isDragging ? 78 : 68,
            decoration: BoxDecoration(
              color: _isDragging ? const Color(0xF21A2944) : const Color(0xEE151F32),
              borderRadius: BorderRadius.circular(_isDragging ? 28 : 24),
              border: Border.all(color: _isDragging ? const Color(0x665B9BFF) : const Color(0x334A6FA8)),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
                BoxShadow(color: Color(0x223B82F6), blurRadius: 18),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < destinations.length; index++)
                  _DockItem(
                    icon: activeIndex == index ? destinations[index].$2 : destinations[index].$1,
                    label: destinations[index].$3,
                    selected: activeIndex == index,
                    onTap: () => widget.onSelected(index),
                  ),
              ],
            ),
          ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 94 : 54,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: selected ? Colors.white : Colors.white70),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TaskcardList extends StatelessWidget {
  const TaskcardList({
    super.key,
    required this.cards,
    required this.query,
    required this.subject,
    required this.status,
    required this.onOpen,
  });

  final List<Taskcard> cards;
  final String query;
  final String subject;
  final String status;
  final Future<void> Function(Taskcard) onOpen;

  @override
  Widget build(BuildContext context) {
    final filtered = cards.where((card) {
      final haystack = '${card.title} ${card.subject} ${card.course} ${card.topic} ${card.teachers.join(' ')}'.toLowerCase();
      return haystack.contains(query.toLowerCase()) &&
          (subject == 'Alle Fächer' || card.subject == subject) &&
          (status == 'Alle Status' || (status == 'Bestätigt' ? card.confirmed : !card.confirmed));
    }).toList();
    if (filtered.isEmpty) return const Center(child: Text('Keine Taskcards gefunden.'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => TaskcardTile(card: filtered[index], onOpen: onOpen),
    );
  }
}

class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.onRefresh, required this.child});

  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF60A5FA),
      backgroundColor: const Color(0xFF151F32),
      displacement: 28,
      strokeWidth: 3,
      onRefresh: () async {
        onRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 650));
      },
      child: child,
    );
  }
}

class TaskcardTile extends StatelessWidget {
  const TaskcardTile({super.key, required this.card, required this.onOpen});

  final Taskcard card;
  final Future<void> Function(Taskcard) onOpen;

  @override
  Widget build(BuildContext context) {
    final color = card.confirmed ? const Color(0xFF34D399) : const Color(0xFFFBBF24);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF121A2A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(card.subject, style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w700))),
                Icon(card.confirmed ? Icons.verified : Icons.schedule, size: 16, color: color),
                const SizedBox(width: 4),
                Text(card.confirmed ? 'Bestätigt' : 'Nicht bestätigt', style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(card.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('${card.grade} · ${card.course} · ${card.topic}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            if (card.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(card.description!, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 10),
            Text('Hinzugefügt von ${card.createdByName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (card.teachers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: card.teachers.map((teacher) => Chip(label: Text(teacher), visualDensity: VisualDensity.compact)).toList()),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => onOpen(card),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Öffnen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
    required this.cards,
    required this.query,
    required this.subject,
    required this.status,
    required this.onQuery,
    required this.onSubject,
    required this.onStatus,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<Taskcard> cards;
  final String query;
  final String subject;
  final String status;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onSubject;
  final ValueChanged<String> onStatus;
  final Future<void> Function(Taskcard) onOpen;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final subjects = ['Alle Fächer', ...cards.map((card) => card.subject).where((item) => item.isNotEmpty).toSet()];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: onQuery,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Thema, Kurs oder Lehrkraft suchen'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(isExpanded: true, initialValue: subject, items: subjects.map((value) => DropdownMenuItem(value: value, child: Text(value, overflow: TextOverflow.ellipsis))).toList(), onChanged: (value) { if (value != null) onSubject(value); })),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(isExpanded: true, initialValue: status, items: const [DropdownMenuItem(value: 'Alle Status', child: Text('Alle Status', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'Bestätigt', child: Text('Bestätigt', overflow: TextOverflow.ellipsis)), DropdownMenuItem(value: 'Nicht bestätigt', child: Text('Nicht bestätigt', overflow: TextOverflow.ellipsis))], onChanged: (value) { if (value != null) onStatus(value); })),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _Refreshable(onRefresh: onRefresh, child: TaskcardList(cards: cards, query: query, subject: subject, status: status, onOpen: onOpen))),
      ],
    );
  }
}

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key, required this.isSignedIn, required this.onSaved});

  final bool isSignedIn;
  final VoidCallback onSaved;

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {for (final field in ['title', 'subject', 'grade', 'course', 'topic', 'teachers', 'url', 'description']) field: TextEditingController()};
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSignedIn) {
      return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.lock_outline, size: 52, color: Color(0xFF60A5FA)),
        const SizedBox(height: 14),
        const Text('Anmelden zum Hinzufügen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Melde dich mit Clerk an, um eine Taskcard zu speichern.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () => _openAuth(context), icon: const Icon(Icons.login), label: const Text('Mit Clerk anmelden')),
      ])));
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text('Neue Taskcard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Füge eine geprüfte Sammlung für alle hinzu.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 18),
          for (final entry in {'title': 'Titel', 'subject': 'Fach', 'grade': 'Stufe / Klasse', 'course': 'Kurs', 'topic': 'Thema', 'teachers': 'Lehrkräfte (mehrere mit Komma)', 'url': 'Taskcard-Link', 'description': 'Kurzbeschreibung (optional)'}.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _controllers[entry.key],
                maxLines: entry.key == 'description' ? 3 : 1,
                keyboardType: entry.key == 'url' ? TextInputType.url : TextInputType.text,
                validator: entry.key == 'description' ? null : (value) => value == null || value.trim().isEmpty ? 'Pflichtfeld' : null,
                decoration: InputDecoration(labelText: entry.value),
              ),
            ),
          FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Wird gespeichert ...' : 'Taskcard speichern')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await TaskcardApi.createCard(_controllers.map((key, controller) => MapEntry(key, controller.text.trim())));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taskcard wurde gespeichert.')));
        widget.onSaved();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.isSignedIn, this.displayName});

  final bool isSignedIn;
  final String? displayName;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _developerMode = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isSignedIn) {
      return Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 34, backgroundColor: Color(0xFF1D4ED8), child: Icon(Icons.person_outline, size: 34)),
        const SizedBox(height: 14),
        const Text('Willkommen bei Taskcard Hub', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Melde dich mit Clerk an, um Taskcards hinzuzufügen und zu melden.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: () => _openAuth(context), icon: const Icon(Icons.login), label: const Text('Anmelden / Registrieren')),
      ])));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      GestureDetector(
        onLongPress: () => setState(() {
          _developerMode = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entwicklermodus aktiviert.')));
        }),
        child: Card(color: const Color(0xFF121A2A), child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF2563EB), child: Icon(Icons.person)), title: Text(widget.displayName ?? 'Nutzer'), subtitle: const Text('Mit Clerk angemeldet'), trailing: const Icon(Icons.verified, color: Color(0xFF34D399)))),
      ),
      const SizedBox(height: 12),
      ListTile(leading: const Icon(Icons.manage_accounts), title: const Text('Konto verwalten'), subtitle: const Text('E-Mail, Passwort und Sitzungen'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Konto')), body: const SafeArea(child: ClerkUserProfileView()))))),
      ListTile(leading: const Icon(Icons.tune), title: const Text('App-Einstellungen'), subtitle: const Text('Darstellung, Verhalten und Datenschutz'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsPage()))),
      ListTile(leading: const Icon(Icons.info_outline), title: const Text('Über Taskcard Hub'), subtitle: const Text('Version, Credits und Hinweise'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppInfoPage()))),
      ListTile(leading: const Icon(Icons.system_update_alt, color: Color(0xFF60A5FA)), title: const Text('Nach Updates suchen'), subtitle: const Text('Aktuelle Version prüfen'), onTap: () => _checkForUpdates(context)),
      if (_developerMode)
        ListTile(
          leading: const Icon(Icons.code, color: Color(0xFF60A5FA)),
          title: const Text('Entwicklermodus', style: TextStyle(color: Color(0xFF60A5FA))),
          subtitle: const Text('Diagnose und versteckte Funktionen'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperPage())),
        ),
      ListTile(leading: const Icon(Icons.logout), title: const Text('Abmelden'), onTap: () => Clerk.instance.signOut()),
    ]);
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 18), Text('Suche nach Updates ...')]),
      ),
    );
    try {
      final update = await checkForAppUpdate();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (!update.isNewer) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Du verwendest bereits die aktuellste Version.')));
        return;
      }
      final open = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(update.title),
          content: Text('Version ${update.version} ist verfügbar.\n\n${update.notes.map((note) => '• $note').join('\n')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Später')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Download öffnen')),
          ],
        ),
      );
      if (open == true) {
        final uri = Uri.tryParse(update.downloadUrl);
        if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download konnte nicht geöffnet werden.')));
        }
      }
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _compactCards = false;
  bool _confirmLinks = true;
  bool _animations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App-Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsSectionTitle('Darstellung'),
          SwitchListTile(
            value: _compactCards,
            onChanged: (value) => setState(() => _compactCards = value),
            title: const Text('Kompakte Taskcards'),
            subtitle: const Text('Weniger Abstand in der Übersicht'),
          ),
          SwitchListTile(
            value: _animations,
            onChanged: (value) => setState(() => _animations = value),
            title: const Text('Animationen'),
            subtitle: const Text('Schwebende Leiste und Übergänge animieren'),
          ),
          const SizedBox(height: 18),
          const _SettingsSectionTitle('Sicherheit'),
          SwitchListTile(
            value: _confirmLinks,
            onChanged: (value) => setState(() => _confirmLinks = value),
            title: const Text('Link-Warnungen anzeigen'),
            subtitle: const Text('Warnung vor nicht bestätigten Taskcard-Links'),
          ),
          const SizedBox(height: 18),
          const _SettingsSectionTitle('Überraschung'),
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24)),
            title: const Text('Geheimes Detail'),
            subtitle: const Text('Tippe hier, wenn du neugierig bist'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => const AlertDialog(
                title: Text('✨ Taskcard Hub'),
                content: Text('Du hast ein kleines Easter Egg gefunden. Danke, dass du den Hub testest!'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }
}

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Über Taskcard Hub')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: BrandMark(size: 88)),
          const SizedBox(height: 18),
          const Center(child: Text('Taskcard Hub', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          const SizedBox(height: 6),
          const Center(child: Text('Version 1.0.0 · Alpha', style: TextStyle(color: Colors.white60))),
          const SizedBox(height: 28),
          const Text('Eine gemeinsame, geordnete Sammlung für Taskcards mit Fächern, Kursen, Themen und Lehrkräften.', style: TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 24),
          const ListTile(leading: Icon(Icons.verified_user, color: Color(0xFF34D399)), title: Text('Moderierte Links'), subtitle: Text('Bestätigte und nicht bestätigte Taskcards werden klar gekennzeichnet.')),
          const ListTile(leading: Icon(Icons.language, color: Color(0xFF60A5FA)), title: Text('Taskcard-Hub-Website'), subtitle: Text('Die App gehört zur Website hub.jojosstudio.de und nutzt deren Online-Funktionen.')),
          const ListTile(leading: Icon(Icons.favorite_outline, color: Color(0xFFF472B6)), title: Text('Credits'), subtitle: Text('Made by Lenodro & Jojosstudio · Powered by Clerk')),
        ],
      ),
    );
  }
}

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entwicklermodus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(child: ListTile(leading: Icon(Icons.bug_report, color: Color(0xFFFBBF24)), title: Text('Alpha-Diagnose'), subtitle: Text('Interne Testfunktionen sind aktiviert.'))),
          const ListTile(title: Text('API'), subtitle: Text(_apiBase)),
          const ListTile(title: Text('Clerk'), subtitle: Text('Native Session und Token-Integration')),
          ListTile(leading: const Icon(Icons.celebration, color: Color(0xFFF472B6)), title: const Text('Konfetti-Test'), onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Easter Egg erfolgreich ausgelöst!')))),
        ],
      ),
    );
  }
}

void _openAuth(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Anmelden')), body: const SafeArea(child: ClerkAuthView()))));
}

class ErrorPanel extends StatefulWidget {
  const ErrorPanel({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(scale: 0.96 + (_controller.value * 0.04), child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 58, color: Color(0xFF60A5FA)),
              const SizedBox(height: 16),
              const Text('Keine Internetverbindung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: widget.onRetry, icon: const Icon(Icons.refresh), label: const Text('Erneut versuchen')),
            ],
          ),
        ),
      ),
    );
  }
}
