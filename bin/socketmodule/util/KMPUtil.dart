class KMPUtil{

  KMPUtil._privateConstructor();

  static final KMPUtil _instance = KMPUtil._privateConstructor();

  static KMPUtil get instance { return _instance;}



   useKMP (List<int> mainList,List<int> modeList){

    int i = 0; // 主串的位置

    int j = 0; // 模式串的位置
    List<int> tempResult=getNext(modeList);

    while (i < mainList.length && j < modeList.length) {

      if (j == -1 || mainList[i] == modeList[j]) { // 当j为-1时，要移动的是i，当然j也要归0

        i++;

        j++;

      } else {

        // i不需要回溯了

        // i = i - j + 1;

        j = tempResult[j]; // j回到指定位置

      }

    }

    if (j == modeList.length) {

      return i - j;

    } else {

      return -1;

    }

   }

   List<int> getNext(List<int> modeList) {

    List<int> next= List.filled(modeList.length, 0);
    next[0] = -1;

    int j = 0;

    int k = -1;

    while (j < modeList.length - 1) {

      if (k == -1 || modeList[j] == modeList[k]) {

        if (modeList[++j] == modeList[++k]) { // 当两个字符相等时要跳过

          next[j] = next[k];

        } else {

          next[j] = k;

        }

      } else {

        k = next[k];

      }

    }
    return next;
  }
}