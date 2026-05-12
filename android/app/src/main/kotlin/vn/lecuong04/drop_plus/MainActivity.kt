package vn.lecuong04.drop_plus

import java.io.File
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import androidx.core.net.toUri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	init {
		System.loadLibrary("drop_plus_core")
	}

	companion object {
		private const val CHANNEL = "vn.lecuong04.drop_plus"
		private const val BUFFER_SIZE = 64 * 1024
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"copyToLocal" -> {
					val srcUriString =
						call.argument<String>("srcUri")
					val dstParent =
						call.argument<String>("dstParent")
					if (srcUriString == null) {
						result.error(
							"INVALID_SRC",
							"srcUri is null",
							null
						)
						return@setMethodCallHandler
					}
					if (dstParent == null) {
						result.error(
							"INVALID_DST",
							"dstParent is null",
							null
						)
						return@setMethodCallHandler
					}
					try {
						val copiedPath = copyToLocal(
							srcUriString.toUri(),
							File(dstParent)
						)
						result.success(copiedPath)
					} catch (e: Exception) {
						result.error(
							"COPY_FAILED",
							e.stackTraceToString(),
							null
						)
					}
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun copyToLocal(
		srcUri: Uri,
		dstParent: File
	): String {
		contentResolver.takePersistableUriPermission(
			srcUri,
			Intent.FLAG_GRANT_READ_URI_PERMISSION
		)
		if (!dstParent.exists()) {
			dstParent.mkdirs()
		}
		val doc = when {
			DocumentsUriHelper.isTreeUri(srcUri) ->
				DocumentFile.fromTreeUri(this, srcUri)

			else ->
				DocumentFile.fromSingleUri(this, srcUri)
		} ?: error("Cannot open document")
		val output = copyDocument(doc, dstParent)
		return output.absolutePath
	}

	private fun copyDocument(
		doc: DocumentFile,
		dstParent: File
	): File {
		val safeName = doc.name ?: "unknown"
		val target = File(dstParent, safeName)
		if (doc.isDirectory) {
			if (!target.exists()) {
				target.mkdirs()
			}
			doc.listFiles().forEach {
				copyDocument(it, target)
			}
			return target
		}
		contentResolver
			.openInputStream(doc.uri)
			?.buffered(BUFFER_SIZE)
			.use { input ->
				requireNotNull(input) {
					"Cannot open input stream"
				}
				target.outputStream()
					.buffered(BUFFER_SIZE)
					.use { output ->
						input.copyTo(
							output,
							BUFFER_SIZE
						)
					}
			}
		return target
	}
}

private object DocumentsUriHelper {
	fun isTreeUri(uri: Uri): Boolean {
		return uri.pathSegments.contains("tree")
	}
}
