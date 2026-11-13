import 'package:mercury/app/bootstrap.dart';
import 'package:mercury/features/edge_player/edge_player_view.dart';

Future<void> main() => bootstrap();

/// The Windows edge player's engine starts here (windows/runner/
/// edge_player.cpp).
@pragma('vm:entry-point')
void edgePlayerMain() => runEdgePlayer();
