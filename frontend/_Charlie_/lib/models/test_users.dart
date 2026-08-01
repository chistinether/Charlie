import 'dart:typed_data';

import 'user_budget.dart';
import 'budget_model.dart';
import 'user_document.dart';





class TransactionModel {

  final String title;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;



  TransactionModel({

    required this.title,

    required this.category,

    required this.amount,

    required this.isIncome,

    required this.date,

  });

}








class TestUser {


  final String name;

  final String email;

  final String password;

  final String phone;

  final String university;

  final String course;

  final int year;



  double balance;

  double income;

  double expenses;

  // Bytes of the user's chosen profile photo, if any. Persisted locally
  // on-device via LocalStorageService (base64, keyed by email) so it
  // survives logout/login and app restarts without needing Firebase
  // Storage.
  Uint8List? photoBytes;

  // Documents the user has uploaded, persisted locally on-device via
  // LocalStorageService rather than Firebase Storage.
  List<UserDocument> documents;



  List<TransactionModel> transactions;



  // Manual budgets
  List<BudgetModel> budgets;



  // AI generated budget
  UserBudget? budget;

  // Previously saved budgets, used for auto-fill / recycle
  List<UserBudget> budgetHistory;







  TestUser({


    required this.name,


    required this.email,


    required this.password,


    required this.phone,


    required this.university,


    required this.course,


    required this.year,



    required this.balance,


    required this.income,


    required this.expenses,



    required this.transactions,



    this.budget,

    this.photoBytes,



    List<BudgetModel>? budgets,

    List<UserBudget>? budgetHistory,

    List<UserDocument>? documents,

  }) : budgets = budgets ?? [],
       budgetHistory = budgetHistory ?? [],
       documents = documents ?? [];

}





// ===============================
// TEST USERS
// ===============================


List<TestUser> testUsers = [





  TestUser(


    name: "Murungi Angella",


    email: "angella@gmail.com",


    password: "123456",


    phone: "0700000000",


    university: "Makerere University",


    course: "Bachelor of Information Technology",


    year: 3,



    balance: 450000,


    income: 700000,


    expenses: 250000,





    transactions: [



      TransactionModel(


        title: "Allowance",


        category: "Income",


        amount: 500000,


        isIncome: true,


        date: DateTime.now(),


      ),






      TransactionModel(


        title: "Lunch",


        category: "Food",


        amount: 15000,


        isIncome: false,


        date: DateTime.now(),


      ),






      TransactionModel(


        title: "Transport",


        category: "Transport",


        amount: 8000,


        isIncome: false,


        date: DateTime.now(),


      ),



    ],





    budgets: [],


    budget: null,



  ),












  TestUser(



    name: "John Peter",



    email: "john@gmail.com",



    password: "123456",



    phone: "0711111111",



    university: "Kyambogo University",



    course: "Computer Science",



    year: 2,




    balance: 780000,


    income: 1000000,


    expenses: 220000,





    transactions: [




      TransactionModel(


        title: "Pocket Money",


        category: "Income",


        amount: 1000000,


        isIncome: true,


        date: DateTime.now(),


      ),






      TransactionModel(


        title: "Books",


        category: "Education",


        amount: 120000,


        isIncome: false,


        date: DateTime.now(),


      ),




    ],





    budgets: [],


    budget: null,



  ),











  TestUser(



    name: "Sarah Amina",



    email: "sarah@gmail.com",



    password: "123456",



    phone: "0722222222",



    university: "MUBS",



    course: "Business Computing",



    year: 1,




    balance: 320000,


    income: 500000,


    expenses: 180000,





    transactions: [




      TransactionModel(


        title: "Parents",


        category: "Income",


        amount: 500000,


        isIncome: true,


        date: DateTime.now(),


      ),






      TransactionModel(


        title: "Food",


        category: "Food",


        amount: 90000,


        isIncome: false,


        date: DateTime.now(),


      ),






      TransactionModel(


        title: "Shopping",


        category: "Shopping",


        amount: 90000,


        isIncome: false,


        date: DateTime.now(),


      ),



    ],





    budgets: [],


    budget: null,



  ),



];