import '../models/user_model.dart';

/// Placeholder NCERT-style topic groupings per class (replace with CMS later).
abstract final class NcertTopicsPlaceholder {
  static List<NcertTopicSection> topicsForClass(int classLevel) {
    if (!StudentClassLevels.isValid(classLevel)) {
      return topicsForClass(StudentClassLevels.min);
    }
    return _byClass[classLevel] ?? topicsForClass(StudentClassLevels.min);
  }

  static final Map<int, List<NcertTopicSection>> _byClass = {
    5: _middlePrimary(5),
    6: _middlePrimary(6),
    7: _middleUpper(7),
    8: _middleUpper(8),
    9: _secondary(9),
    10: _secondary(10),
  };

  static List<NcertTopicSection> _middlePrimary(int c) => [
        NcertTopicSection(
          subject: 'Mathematics',
          topics: [
            'Ch $c.1 — Large numbers & place value (NCERT style)',
            'Ch $c.2 — Operations & word problems',
            'Ch $c.3 — Basic geometry & measurement',
          ],
        ),
        NcertTopicSection(
          subject: 'Environmental Studies / Science',
          topics: [
            'Unit $c.A — My surroundings & living things',
            'Unit $c.B — Matter & everyday science',
            'Unit $c.C — Earth & sky (placeholder)',
          ],
        ),
        NcertTopicSection(
          subject: 'English',
          topics: [
            'Reader: prose & poetry (Class $c themes)',
            'Grammar: tenses, articles, composition',
          ],
        ),
      ];

  static List<NcertTopicSection> _middleUpper(int c) => [
        NcertTopicSection(
          subject: 'Mathematics',
          topics: [
            'Ch $c.1 — Integers, fractions & decimals',
            'Ch $c.2 — Algebra basics & simple equations',
            'Ch $c.3 — Data handling & symmetry (NCERT map)',
          ],
        ),
        NcertTopicSection(
          subject: 'Science',
          topics: [
            'Physics: motion, force & energy (Class $c)',
            'Chemistry: matter & reactions (intro)',
            'Biology: nutrition & respiration (placeholder)',
          ],
        ),
        NcertTopicSection(
          subject: 'Social Science',
          topics: [
            'History: themes for Class $c (NCERT overview)',
            'Civics: democracy & local government (placeholder)',
            'Geography: resources & maps',
          ],
        ),
      ];

  static List<NcertTopicSection> _secondary(int c) => [
        NcertTopicSection(
          subject: 'Mathematics',
          topics: [
            'Ch $c.1 — Number systems & polynomials',
            'Ch $c.2 — Coordinate geometry & linear equations',
            'Ch $c.3 — Triangles, circles & constructions',
            'Ch $c.4 — Statistics & probability (intro)',
          ],
        ),
        NcertTopicSection(
          subject: 'Science',
          topics: [
            'Chemistry: atoms, structure of matter (Class $c)',
            'Physics: work, energy, sound & light',
            'Biology: tissues, life processes, heredity (map)',
          ],
        ),
        NcertTopicSection(
          subject: c == 10 ? 'Social Science (board focus)' : 'Social Science',
          topics: [
            'History: nationalism & modern India (NCERT lines)',
            'Political science: institutions & rights',
            'Economics: development & sectors (placeholder)',
          ],
        ),
      ];
}

class NcertTopicSection {
  const NcertTopicSection({
    required this.subject,
    required this.topics,
  });

  final String subject;
  final List<String> topics;
}
