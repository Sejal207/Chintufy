import 'package:flutter/material.dart';
import '../models/request.dart';
import '../services/database_service.dart';
import 'package:provider/provider.dart';

class RequestedItemsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Requested Items'),
      ),
      body: StreamBuilder<List<Request>>(
        stream: databaseService.requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No requests yet'));
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                leading: Icon(Icons.shopping_basket),
                title: Text(request.productName),
                subtitle: Text('Requested on: ${request.timestamp.toString()}'),
                trailing: request.status == 'pending'
                    ? Chip(
                        label: Text('Pending'),
                        backgroundColor: Colors.orange[100],
                      )
                    : Chip(
                        label: Text(request.status),
                        backgroundColor: Colors.green[100],
                      ),
              );
            },
          );
        },
      ),
    );
  }
}