package dev.panimal.shadermaxxing;

import dev.panimal.shadermaxxing.network.VFXSyncS2CPacket;
import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.command.v1.CommandRegistrationCallback;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.command.argument.BlockPosArgumentType;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.BlockPos;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collection;
import java.util.Optional;
import java.util.stream.Collectors;

public class Shadermaxxing implements ModInitializer {
    public static final String MOD_ID = "shadermaxxing";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    public static final Identifier CLIENT_SYNC_PACKET_ID = Identifier.of(MOD_ID, "shader_event");

    @Override
    public void onInitialize() {
        PayloadTypeRegistry.playS2C().register(VFXSyncS2CPacket.ID, VFXSyncS2CPacket.CODEC);

        CommandRegistrationCallback.EVENT.register((dispatcher, dedicated) -> {
            dispatcher.register(
                    CommandManager.literal("shaderevent")
                            .requires(source -> source.hasPermissionLevel(2))
                            .then(CommandManager.argument("pos", BlockPosArgumentType.blockPos())
                                    .executes(ctx -> {
                                        BlockPos pos = BlockPosArgumentType.getBlockPos(ctx, "pos");
                                        ServerCommandSource source = ctx.getSource();
                                        MinecraftServer server = source.getServer();

                                        server.execute(() -> {
                                            PacketByteBuf buf = PacketByteBufs.create();
                                            buf.writeBlockPos(pos);

                                            Collection<ServerPlayerEntity> targets = Optional.ofNullable(source.getEntity())
                                                    .filter(ServerPlayerEntity.class::isInstance)
                                                    .map(e -> ((ServerPlayerEntity) e).getWorld()
                                                            .getPlayers().stream()
                                                            .filter(p -> p instanceof ServerPlayerEntity)
                                                            .map(p -> (ServerPlayerEntity) p)
                                                            .collect(Collectors.toList())
                                                    )
                                                    .orElseGet(() -> server.getPlayerManager().getPlayerList());

                                            for (ServerPlayerEntity player : targets) {
                                                ServerPlayNetworking.send(player, new VFXSyncS2CPacket(pos));
                                            }
                                        });
                                        return 1;
                                    })
                            )
            );
        });
    }
}