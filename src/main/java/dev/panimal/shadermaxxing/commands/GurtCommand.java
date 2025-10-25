package dev.panimal.shadermaxxing.commands;

import com.mojang.brigadier.CommandDispatcher;
// import jdk.swing.interop.DispatcherWrapper;
import net.minecraft.command.argument.EntityArgumentType;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.text.Text;

import java.util.Collection;

public class GurtCommand {

    public static void register(CommandDispatcher<ServerCommandSource>dispatcher) {
        dispatcher.register(CommandManager.literal("gurt")
            .then(CommandManager.argument("target", EntityArgumentType.players())
                .executes(ctx -> {
                    Collection<ServerPlayerEntity> players = EntityArgumentType.getPlayers(ctx, "target");
                    for (ServerPlayerEntity player : players) {
                        player.sendMessage(Text.literal("yo"), false);
                    }
                    return players.size();
                })
            ));
    }

}
