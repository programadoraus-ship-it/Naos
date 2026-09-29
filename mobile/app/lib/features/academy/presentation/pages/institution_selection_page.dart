import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'institution_confirmation_page.dart';

class InstitutionSelectionPage extends StatefulWidget {
  const InstitutionSelectionPage({super.key});

  @override
  State<InstitutionSelectionPage> createState() =>
      _InstitutionSelectionPageState();
}

class _InstitutionSelectionPageState
    extends State<InstitutionSelectionPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _institutions = [];
  List<Map<String, dynamic>> _filteredInstitutions = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterInstitutions);

    _loadInstitutions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    try {
      final data = await Supabase.instance.client
          .from('institutions')
          .select()
          .order('name');

      if (!mounted) return;

      setState(() {
        _institutions = List<Map<String, dynamic>>.from(data);
        _filteredInstitutions = _institutions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load institutions.';
      });

      debugPrint('Error loading institutions: $e');
    }
  }

  void _filterInstitutions() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredInstitutions = _institutions;
      } else {
        _filteredInstitutions = _institutions.where((institution) {
          final name =
              (institution['name'] ?? '').toString().toLowerCase();

          final shortName =
              (institution['short_name'] ?? '').toString().toLowerCase();

          final city =
              (institution['city'] ?? '').toString().toLowerCase();

          return name.contains(query) ||
              shortName.contains(query) ||
              city.contains(query);
        }).toList();
      }
    });
  }

  void _selectInstitution(Map<String, dynamic> institution) {
    final institutionId =
        institution['id']?.toString() ?? '';

    final name =
        institution['name']?.toString() ?? 'Institution';

    final shortName =
        institution['short_name']?.toString() ?? '';

    final city =
        institution['city']?.toString() ?? '';

    final country =
        institution['country']?.toString() ?? '';

    final location = [
      city,
      country,
    ].where((value) => value.isNotEmpty).join(', ');

    final logoUrl =
        institution['logo_url']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstitutionConfirmationPage(
          institutionId: institutionId,
          name: name,
          shortName: shortName,
          location: location,
          logoUrl: logoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Find Your Institution',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Search for the English institution you are enrolled in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: 500,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search institution...',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF7C83FF),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF11162B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF30385C),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF30385C),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF7C83FF),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C83FF),
                    ),
                  )

                else if (_errorMessage != null)
                  _ErrorMessage(
                    message: _errorMessage!,
                    onRetry: _loadInstitutions,
                  )

                else if (_filteredInstitutions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'No institutions found.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                  )

                else
                  ..._filteredInstitutions.map((institution) {
                    final name =
                        institution['name']?.toString() ??
                            'Institution';

                    final city =
                        institution['city']?.toString() ?? '';

                    final country =
                        institution['country']?.toString() ?? '';

                    final location = [
                      city,
                      country,
                    ].where((value) => value.isNotEmpty).join(', ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _InstitutionCard(
                        name: name,
                        location: location,
                        onTap: () {
                          _selectInstitution(institution);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final String name;
  final String location;
  final VoidCallback onTap;

  const _InstitutionCard({
    required this.name,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF11162B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF30385C),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2140),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF7C83FF),
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 15,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            location.isEmpty
                                ? 'Location unavailable'
                                : location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorMessage({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Try again',
            style: TextStyle(
              color: Color(0xFF7C83FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}