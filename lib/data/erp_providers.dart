import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'erp_repository.dart';

final erpRepositoryProvider = Provider<ErpRepository>((ref) {
  return ErpRepository();
});
