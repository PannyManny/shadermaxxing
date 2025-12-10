package dev.panimal.shadermaxxing.commands;

import com.mojang.brigadier.CommandDispatcher;
import dev.panimal.shadermaxxing.network.VFXSyncS2CPacket;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.command.argument.BlockPosArgumentType;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.math.BlockPos;

import java.util.Collection;
import java.util.Optional;
import java.util.stream.Collectors;

public final class ShaderEventCommand {

    private ShaderEventCommand() {}

    public static void register(CommandDispatcher<ServerCommandSource> dispatcher) {
        dispatcher.register(
                CommandManager.literal("shaderevent")
                        .requires(source -> source.hasPermissionLevel(2))
                        .then(CommandManager.argument("pos", BlockPosArgumentType.blockPos())
                                .executes(ctx -> {
                                    BlockPos pos = BlockPosArgumentType.getBlockPos(ctx, "pos");
                                    ServerCommandSource source = ctx.getSource();

                                    source.getServer().execute(() -> {
                                        Collection<ServerPlayerEntity> targets =
                                                Optional.ofNullable(source.getEntity())
                                                        .filter(ServerPlayerEntity.class::isInstance)
                                                        .map(e -> ((ServerPlayerEntity) e).getWorld()
                                                                .getPlayers().stream()
                                                                .map(p -> (ServerPlayerEntity) p)
                                                                .collect(Collectors.toList()))
                                                        .orElseGet(() -> source.getServer()
                                                                .getPlayerManager()
                                                                .getPlayerList());

                                        for (ServerPlayerEntity player : targets) {
                                            ServerPlayNetworking.send(player, new VFXSyncS2CPacket(pos));
                                        }
                                    });

                                    return 1;
                                })
                        )
        );
    }
}
