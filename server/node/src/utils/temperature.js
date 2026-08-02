// 디자인에 맞게 수정 필요
exports.getTemperatureLevel = (temperature) => {
  if (temperature >= 80) return 5;
  if (temperature >= 60) return 4;
  if (temperature >= 40) return 3;
  if (temperature >= 20) return 2;
  return 1;
};
