class MyOwnFunding {
  final double amount;

  MyOwnFunding({required this.amount});

  factory MyOwnFunding.fromJson(Map<String, dynamic> json) {
    return MyOwnFunding(
      amount: double.parse(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toStringAsFixed(2),
    };
  }
}