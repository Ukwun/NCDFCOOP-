/// Email service interface for sending emails
abstract class EmailService {
  /// Send a simple text email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    Map<String, String>? attachments,
  });

  /// Send an HTML email
  Future<bool> sendHtmlEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? plainTextBody,
    String? cc,
    String? bcc,
    Map<String, String>? attachments,
  });

  /// Send invoice email
  Future<bool> sendInvoiceEmail({
    required String to,
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? cc,
    String? notes,
  });
}

/// Mock email service implementation for testing
class MockEmailService implements EmailService {
  final List<Map<String, dynamic>> sentEmails = [];

  @override
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    Map<String, String>? attachments,
  }) async {
    try {
      sentEmails.add({
        'to': to,
        'subject': subject,
        'body': body,
        'cc': cc,
        'bcc': bcc,
        'attachments': attachments,
        'type': 'text',
        'timestamp': DateTime.now(),
      });
      print('📧 Mock email sent to $to: $subject');
      return true;
    } catch (e) {
      print('❌ Failed to send mock email: $e');
      return false;
    }
  }

  @override
  Future<bool> sendHtmlEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? plainTextBody,
    String? cc,
    String? bcc,
    Map<String, String>? attachments,
  }) async {
    try {
      sentEmails.add({
        'to': to,
        'subject': subject,
        'htmlBody': htmlBody,
        'plainTextBody': plainTextBody,
        'cc': cc,
        'bcc': bcc,
        'attachments': attachments,
        'type': 'html',
        'timestamp': DateTime.now(),
      });
      print('📧 Mock HTML email sent to $to: $subject');
      return true;
    } catch (e) {
      print('❌ Failed to send mock HTML email: $e');
      return false;
    }
  }

  @override
  Future<bool> sendInvoiceEmail({
    required String to,
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? cc,
    String? notes,
  }) async {
    try {
      final htmlBody = _buildInvoiceEmailHtml(
        customerName: customerName,
        invoiceNumber: invoiceNumber,
        amount: amount,
        currency: currency,
        dueDate: dueDate,
        notes: notes,
      );

      return await sendHtmlEmail(
        to: to,
        subject:
            'Invoice #$invoiceNumber - $currency ${amount.toStringAsFixed(2)}',
        htmlBody: htmlBody,
        plainTextBody:
            'Invoice #$invoiceNumber is due on ${dueDate.toString()}',
        cc: cc,
      );
    } catch (e) {
      print('❌ Failed to send invoice email: $e');
      return false;
    }
  }

  String _buildInvoiceEmailHtml({
    required String customerName,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? notes,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #1A4E00; color: white; padding: 20px; border-radius: 5px; }
        .invoice-details { margin: 20px 0; }
        .amount { font-size: 24px; font-weight: bold; color: #1A4E00; }
        .due-date { color: #E61456; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; font-size: 12px; color: #666; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>NCDF COOP</h1>
          <h2>Invoice #$invoiceNumber</h2>
        </div>
        
        <div class="invoice-details">
          <p>Dear $customerName,</p>
          
          <p>Thank you for your business. Your invoice is ready.</p>
          
          <div class="amount">$currency ${amount.toStringAsFixed(2)}</div>
          
          <p class="due-date">Due Date: ${dueDate.toString().split(' ')[0]}</p>
          
          ${notes != null ? '<p><strong>Notes:</strong> $notes</p>' : ''}
          
          <p>Please contact us if you have any questions about this invoice.</p>
        </div>
        
        <div class="footer">
          <p>&copy; 2026 NCDF Coop Commerce. All rights reserved.</p>
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// Get sent emails for testing
  List<Map<String, dynamic>> getSentEmails() => sentEmails;

  /// Clear sent emails
  void clearSentEmails() => sentEmails.clear();
}

/// Provider for email service (can be implemented with provider pattern later)
EmailService createEmailService() {
  // For now, use mock service
  // In production, implement real email service with Firebase Cloud Functions or SendGrid
  return MockEmailService();
}
