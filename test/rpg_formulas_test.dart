import 'package:flutter_test/flutter_test.dart';

// Fórmulas centrais do RPG Despertar do Caos:
int calculateMaxFv(int constitution, int dv) {
  return constitution * dv;
}

int calculateMaxVigor(int constitution) {
  return constitution * 2;
}

double calculateCarryingCapacity(double constitution, double strength) {
  return constitution * strength;
}

int calculateSkillPoints(int attributeValue) {
  return attributeValue * 3;
}

void main() {
  group('Fórmulas de Ficha do RPG - Despertar do Caos', () {
    test('Cálculo de FV Máxima (Constituição * Dado de Vida)', () {
      // CON = 12, DV = 8 (e.g. classe intermediária)
      expect(calculateMaxFv(12, 8), 96);
      
      // CON = 15, DV = 10 (e.g. Guerreiro vigoroso)
      expect(calculateMaxFv(15, 10), 150);

      // CON = 10, DV = 6 (e.g. Conjurador/Pesquisador)
      expect(calculateMaxFv(10, 6), 60);
    });

    test('Cálculo de Vigor Máximo (Constituição * 2)', () {
      expect(calculateMaxVigor(12), 24);
      expect(calculateMaxVigor(15), 30);
      expect(calculateMaxVigor(8), 16);
    });

    test('Cálculo de Capacidade de Carga em Kg (CON * FOR)', () {
      expect(calculateCarryingCapacity(12.0, 10.0), 120.0);
      expect(calculateCarryingCapacity(15.0, 15.0), 225.0);
      expect(calculateCarryingCapacity(8.0, 8.0), 64.0);
    });

    test('Cálculo de Pontos de Perícias Vinculadas (Atributo * 3)', () {
      expect(calculateSkillPoints(12), 36);
      expect(calculateSkillPoints(15), 45);
      expect(calculateSkillPoints(8), 24);
    });
  });
}
