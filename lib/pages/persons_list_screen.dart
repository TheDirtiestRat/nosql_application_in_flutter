import 'package:flutter/material.dart';
import 'package:nosql_application/pages/record_person_screen.dart';
import 'package:nosql_application/services/couch_db_services.dart';

class PeopleScreen extends StatefulWidget {
  final CouchDBService couchDbService;

  const PeopleScreen({super.key, required this.couchDbService});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final searchController = TextEditingController();

  List<Map<String, dynamic>> people = [];
  final Set<String> _deletingIds = {};

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople({String search = ''}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await widget.couchDbService.getRecord(search: search);

      if (!mounted) return;

      setState(() {
        people = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _confirmAndDeletePerson(Map<String, dynamic> person) async {
    final id = person['_id']?.toString();
    final rev = person['_rev']?.toString();
    final firstName = person['first_name']?.toString() ?? '';
    final lastName = person['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();

    if (id == null || rev == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot delete this record: CouchDB ID or revision is missing.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text(
          'Are you sure you want to delete '
          '${name.isEmpty ? 'this person' : name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _deletingIds.add(id));

    try {
      await widget.couchDbService.deleteRecord(id: id, rev: rev);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${name.isEmpty ? 'Person' : name} deleted')),
      );

      await _loadPeople(search: searchController.text.trim());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete person: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('People'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.06 * 255).round()),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => _loadPeople(search: value.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by first or last name',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildPeopleList()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RecordPersonScreen(couchDbService: widget.couchDbService),
            ),
          );

          if (saved == true && mounted) {
            _loadPeople(search: searchController.text.trim());
          }
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Person'),
      ),
    );
  }

  Widget _buildPeopleList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 12),
            Text(errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  _loadPeople(search: searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (people.isEmpty) {
      return const Center(
        child: Text('No people found. Try adding a new record.'),
      );
    }

    return ListView.builder(
      itemCount: people.length,
      itemBuilder: (context, index) {
        final person = people[index];
        final id = person['_id']?.toString();
        final firstName = person['first_name']?.toString() ?? '';
        final lastName = person['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final isDeleting = id != null && _deletingIds.contains(id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.04 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordPersonScreen(
                      couchDbService: widget.couchDbService,
                      person: person,
                    ),
                  ),
                );

                if (saved == true && mounted) {
                  _loadPeople(search: searchController.text.trim());
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        firstName.isEmpty ? '?' : firstName[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Unnamed person' : fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: ${person['age'] ?? '?'} ? Year born: ${person['year_born'] ?? '?'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Delete person',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _confirmAndDeletePerson(person),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
