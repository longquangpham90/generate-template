package ${PACKAGE_NAME}

import android.content.Context
import com.studio.common.ui.base.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject

@HiltViewModel
class ${NAME}ViewModel
@Inject
constructor(@ApplicationContext val context: Context) : BaseViewModel() {
}