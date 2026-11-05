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

  Future<void> _confirmAndDeletePerson(
    Map<String, dynamic> person,
  ) async {
    final id = person['_id']?.toString();
    final rev = person['_rev']?.toString();
    final firstName = person['first_name']?.toString() ?? '';
    final lastName = person['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();

    if (id == null || rev == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete this record: CouchDB ID or revision is missing.'),
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
        SnackBar(
          content: Text('${name.isEmpty ? 'Person' : name} deleted'),
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (value) => _loadPeople(search: value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by first or last name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildPeopleList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => RecordPersonScreen(
                couchDbService: widget.couchDbService,
              ),
            ),
          );

          if (saved == true && mounted) {
            _loadPeople(search: searchController.text.trim());
          }
        },
        icon: const Icon(Icons.person_add),
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
      return const Center(child: Text('No people found.'));
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.only(
              left: 16,
              top: 8,
              bottom: 8,
              right: 4,
            ),
            leading: CircleAvatar(
              child: Text(firstName.isEmpty ? '?' : firstName[0].toUpperCase()),
            ),
            title: Text(fullName.isEmpty ? 'Unnamed person' : fullName),
            subtitle: Text(
              'Age: ${person['age'] ?? '—'}'
              '  •  Year born: ${person['year_born'] ?? '—'}',
            ),
            trailing: isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Delete person',
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: () => _confirmAndDeletePerson(person),
                  ),
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
          ),
        );
      },
    );
  }
}