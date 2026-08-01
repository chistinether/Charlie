enum RecommendationType {

  warning,

  suggestion,

  improvement,

  positive,

}




class AIRecommendation {


  final String title;


  final String message;


  final String category;


  final RecommendationType type;


  final double? suggestedAmount;




  AIRecommendation({

    required this.title,

    required this.message,

    required this.category,

    required this.type,

    this.suggestedAmount,

  });





  String get icon {


    switch(type){

      case RecommendationType.warning:
        return "⚠️";


      case RecommendationType.suggestion:
        return "💡";


      case RecommendationType.improvement:
        return "📈";


      case RecommendationType.positive:
        return "✅";

    }

  }





  String get displayText {


    return "$icon $title\n$message";


  }


}